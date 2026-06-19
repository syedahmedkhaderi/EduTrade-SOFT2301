import Foundation

/// Mock transaction + checkout service.
final class MockTransactionService: TransactionServiceProtocol {

    private let store: MockStore
    init(store: MockStore) { self.store = store }

    func previewCheckout(listingID: String) async throws -> CheckoutPreview {
        guard let listing = await store.getListing(id: listingID) else { throw AppError.notFound }
        let commission = (listing.price * Constants.commissionRate).roundedTo2()
        return CheckoutPreview(
            listing: listing,
            itemPrice: listing.price,
            commissionAmount: commission,
            totalCharge: listing.price.roundedTo2()
        )
    }

    func createPaymentIntent(listingID: String, buyerID: String) async throws -> Transaction {
        guard let listing = await store.getListing(id: listingID) else { throw AppError.notFound }

        // Business rules
        if listing.sellerID == buyerID { throw AppError.cannotBuyOwnListing }
        if listing.status == .sold { throw AppError.alreadyPurchased }
        guard listing.moderationStatus == .approved else { throw AppError.moderationRejected }

        var tx = Transaction.make(listing: listing, buyerID: buyerID)
        tx.status = .pending
        await store.upsertTransaction(tx)
        return tx
    }

    func completeTransaction(_ transaction: Transaction) async throws -> Transaction {
        var tx = transaction
        tx.status = .completed
        tx.completedAt = .now
        await store.upsertTransaction(tx)

        // Mark the listing as sold
        if var listing = await store.getListing(id: tx.listingID) {
            listing.status = .sold
            listing.updatedAt = .now
            await store.upsertListing(listing)
        }
        return tx
    }

    func fetchTransactions(userID: String, role: TransactionRole) async throws -> [Transaction] {
        let all = await store.transactions
        switch role {
        case .buyer:  return all.filter { $0.buyerID == userID }.sorted { $0.createdAt > $1.createdAt }
        case .seller: return all.filter { $0.sellerID == userID }.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func fetchAllTransactions() async throws -> [Transaction] {
        await store.transactions.sorted { $0.createdAt > $1.createdAt }
    }
}
