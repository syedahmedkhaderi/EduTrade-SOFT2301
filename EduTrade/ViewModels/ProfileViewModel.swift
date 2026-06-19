import Foundation

/// Profile ViewModel (spec §12.12, §12.13, §12.14, §12.16).
@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var myListings: [Listing] = []
    @Published var purchases: [Transaction] = []
    @Published var sales: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let listingService: ListingServiceProtocol
    private let txService: TransactionServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.listingService = appState.services.listings
        self.txService = appState.services.transactions
    }

    func loadAll() async {
        guard let user = AppState.sessionUser() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            myListings = try await listingService.fetchListings(bySeller: user.id, includeSold: true)
            purchases = try await txService.fetchTransactions(userID: user.id, role: .buyer)
            sales = try await txService.fetchTransactions(userID: user.id, role: .seller)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var activeListings: [Listing]  { myListings.filter { $0.status == .active } }
    var soldListings: [Listing]    { myListings.filter { $0.status == .sold } }
    var draftListings: [Listing]   { myListings.filter { $0.status == .draft } }

    func deleteListing(_ id: String) async {
        try? await listingService.deleteListing(id: id)
        await loadAll()
    }

    func markAsSold(_ id: String) async {
        try? await listingService.markAsSold(id: id)
        await loadAll()
    }
}
