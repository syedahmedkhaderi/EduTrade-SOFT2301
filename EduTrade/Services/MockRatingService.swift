import Foundation

/// Mock rating service.
final class MockRatingService: RatingServiceProtocol {

    private let store: MockStore
    init(store: MockStore) { self.store = store }

    func fetchRating(for transactionID: String, byRater raterID: String) async throws -> Rating? {
        await store.ratings.first { $0.transactionID == transactionID && $0.raterID == raterID }
    }

    func submitRating(
        transactionID: String,
        raterID: String,
        rateeID: String,
        stars: Int,
        comment: String?
    ) async throws -> Rating {
        guard Validators.isValidStarCount(stars) else { throw AppError.generic("Stars must be 1–5.") }

        let existing = await store.ratings.first {
            $0.transactionID == transactionID && $0.raterID == raterID
        }
        if existing != nil { throw AppError.ratingAlreadyExists }

        let rating = Rating(
            transactionID: transactionID,
            raterID: raterID,
            rateeID: rateeID,
            stars: stars,
            comment: comment
        )
        await store.upsertRating(rating)

        // Recompute ratee's average
        try await recomputeUserRating(userID: rateeID)
        return rating
    }

    func ratingsFor(userIDs: [String]) async throws -> [Rating] {
        await store.ratings.filter { userIDs.contains($0.rateeID) }
    }

    func recomputeUserRating(userID: String) async throws {
        let userRatings = await store.ratings.filter { $0.rateeID == userID }
        guard var user = await store.getUser(id: userID) else { return }
        if userRatings.isEmpty {
            user.averageRating = 0
            user.totalRatings = 0
        } else {
            let sum = userRatings.reduce(0.0) { $0 + Double($1.stars) }
            user.averageRating = (sum / Double(userRatings.count)).roundedTo2()
            user.totalRatings = userRatings.count
        }
        await store.upsertUser(user)
    }
}
