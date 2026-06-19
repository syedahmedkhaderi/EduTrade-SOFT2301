import Foundation

// MARK: - User

struct User: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var fullName: String
    var universityEmail: String
    var isEmailVerified: Bool
    var profileImageURL: String?
    var averageRating: Double
    var totalRatings: Int
    var isAdmin: Bool
    var isSuspended: Bool
    var createdAt: Date
    var stripeConnectedAccountID: String?

    init(
        id: String = UUID().uuidString,
        fullName: String,
        universityEmail: String,
        isEmailVerified: Bool = false,
        profileImageURL: String? = nil,
        averageRating: Double = 0,
        totalRatings: Int = 0,
        isAdmin: Bool = false,
        isSuspended: Bool = false,
        createdAt: Date = .now,
        stripeConnectedAccountID: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.universityEmail = universityEmail
        self.isEmailVerified = isEmailVerified
        self.profileImageURL = profileImageURL
        self.averageRating = averageRating
        self.totalRatings = totalRatings
        self.isAdmin = isAdmin
        self.isSuspended = isSuspended
        self.createdAt = createdAt
        self.stripeConnectedAccountID = stripeConnectedAccountID
    }
}
