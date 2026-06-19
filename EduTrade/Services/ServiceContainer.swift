import Foundation

/// Central dependency injection container.
/// Provides all services to the app. Swap mock implementations for live ones here.
@MainActor
final class ServiceContainer {

    static let shared = ServiceContainer()

    let store: MockStore
    let auth: AuthServiceProtocol
    let listings: ListingServiceProtocol
    let transactions: TransactionServiceProtocol
    let ratings: RatingServiceProtocol
    let admin: AdminServiceProtocol
    let storage: StorageServiceProtocol

    private init() {
        let store = MockStore()
        // Bootstrap is async (actor); kick it off synchronously at first use.
        self.store = store
        self.auth = MockAuthService(store: store)
        self.listings = MockListingService(store: store)
        self.transactions = MockTransactionService(store: store)
        self.ratings = MockRatingService(store: store)
        self.admin = MockAdminService(store: store)
        self.storage = MockStorageService()

        Task { await store.bootstrap() }
    }

    /// Reset all mock data back to the seeded state (debug / admin tool).
    func resetMockData() {
        Task {
            await store.resetAll()
            await store.bootstrap()
        }
    }
}
