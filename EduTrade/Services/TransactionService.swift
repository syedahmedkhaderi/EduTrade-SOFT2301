import Foundation

/// Transaction + checkout service (spec §4.6, §9.3, §9.4, §10.3).
protocol TransactionServiceProtocol {
    /// Returns a checkout preview (price breakdown) for a listing.
    func previewCheckout(listingID: String) async throws -> CheckoutPreview
    /// Creates a payment intent (mock returns a fake client secret) and records the transaction.
    func createPaymentIntent(listingID: String, buyerID: String) async throws -> Transaction
    /// Records a completed transaction + marks listing as sold.
    func completeTransaction(_ transaction: Transaction) async throws -> Transaction
    /// Fetches transactions where the user is buyer (purchases) or seller (sales).
    func fetchTransactions(userID: String, role: TransactionRole) async throws -> [Transaction]
    /// All transactions (admin only).
    func fetchAllTransactions() async throws -> [Transaction]
}

enum TransactionRole {
    case buyer, seller
}
