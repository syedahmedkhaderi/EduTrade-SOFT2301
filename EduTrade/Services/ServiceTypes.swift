import Foundation

/// Structured query for listing search (spec §10.2).
struct SearchQuery: Equatable {
    var text: String?
    var subject: String?
    var courseCode: String?
    var minPrice: Double?
    var maxPrice: Double?
    var conditions: [Condition]
    var cursor: String?     // pagination cursor (nil = first page)
    var pageSize: Int = Constants.pageSize

    static let empty = SearchQuery(text: nil, subject: nil, courseCode: nil, minPrice: nil, maxPrice: nil, conditions: [])
}

/// Paginated result wrapper.
struct ListingPage: Equatable {
    var listings: [Listing]
    var nextCursor: String?
}

/// Checkout preview shown to buyer before they commit (spec §10.3).
struct CheckoutPreview: Equatable {
    var listing: Listing
    var itemPrice: Double
    var commissionAmount: Double
    var totalCharge: Double
}

/// Auth session carried by AppState.
struct AuthSession: Equatable {
    var user: User
    var token: String
}
