import Foundation

/// Rating + review service (spec §4.5, §10.4).
protocol RatingServiceProtocol {
    func fetchRating(for transactionID: String, byRater raterID: String) async throws -> Rating?
    func submitRating(
        transactionID: String,
        raterID: String,
        rateeID: String,
        stars: Int,
        comment: String?
    ) async throws -> Rating
    func ratingsFor(userIDs: [String]) async throws -> [Rating]
    /// Recomputes average rating and total count for a user.
    func recomputeUserRating(userID: String) async throws
}
