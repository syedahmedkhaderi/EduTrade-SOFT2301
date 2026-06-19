import Foundation

enum TransactionStatus: String, Codable, CaseIterable {
    case pending
    case completed
    case refunded
    case disputed
}

struct Transaction: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var listingID: String
    var buyerID: String
    var sellerID: String
    var itemPrice: Double
    var commissionAmount: Double
    var sellerPayout: Double
    var status: TransactionStatus
    var stripePaymentIntentID: String
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        listingID: String,
        buyerID: String,
        sellerID: String,
        itemPrice: Double,
        commissionAmount: Double,
        sellerPayout: Double,
        status: TransactionStatus = .pending,
        stripePaymentIntentID: String = "",
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.buyerID = buyerID
        self.sellerID = sellerID
        self.itemPrice = itemPrice
        self.commissionAmount = commissionAmount
        self.sellerPayout = sellerPayout
        self.status = status
        self.stripePaymentIntentID = stripePaymentIntentID
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    /// Build a transaction from a listing + buyer, applying the 10% platform commission.
    static func make(
        listing: Listing,
        buyerID: String,
        paymentIntentID: String = "mock_pi_\(UUID().uuidString.prefix(8))"
    ) -> Transaction {
        let commission = (listing.price * 0.10).roundedTo2()
        let payout = (listing.price - commission).roundedTo2()
        return Transaction(
            listingID: listing.id,
            buyerID: buyerID,
            sellerID: listing.sellerID,
            itemPrice: listing.price,
            commissionAmount: commission,
            sellerPayout: payout,
            stripePaymentIntentID: paymentIntentID
        )
    }
}

extension Double {
    /// Round to two decimal places (currency).
    func roundedTo2() -> Double {
        (self * 100).rounded() / 100
    }
}
