import Foundation

struct Rating: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var transactionID: String
    var raterID: String
    var rateeID: String
    var stars: Int
    var comment: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        transactionID: String,
        raterID: String,
        rateeID: String,
        stars: Int,
        comment: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.transactionID = transactionID
        self.raterID = raterID
        self.rateeID = rateeID
        self.stars = stars
        self.comment = comment
        self.createdAt = createdAt
    }

    /// Stars must be 1...5.
    init(transactionID: String, raterID: String, rateeID: String, stars: Int, comment: String?) {
        self.id = UUID().uuidString
        self.transactionID = transactionID
        self.raterID = raterID
        self.rateeID = rateeID
        self.stars = max(1, min(5, stars))
        self.comment = comment
        self.createdAt = .now
    }
}
