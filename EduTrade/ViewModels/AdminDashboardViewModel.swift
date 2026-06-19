import Foundation

/// Admin dashboard ViewModel (spec §4.9, §12.17–12.20).
@MainActor
final class AdminDashboardViewModel: ObservableObject {

    @Published var flaggedListings: [Listing] = []
    @Published var reports: [Report] = []
    @Published var users: [User] = []
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Analytics summary
    var totalUsers: Int { users.filter { !$0.isAdmin }.count }
    var totalActiveListings: Int { _activeListingCount }
    var totalCommission: Double { transactions.filter { $0.status == .completed }.reduce(0) { $0 + $1.commissionAmount } }
    var totalTransactions: Int { transactions.count }

    private var _activeListingCount: Int = 0

    private let admin: AdminServiceProtocol
    private let store: MockStore
    private let txService: TransactionServiceProtocol
    private let listingService: ListingServiceProtocol

    init() {
        let appState = AppState.current!
        self.admin = appState.services.admin
        self.store = appState.services.store
        self.txService = appState.services.transactions
        self.listingService = appState.services.listings
    }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            flaggedListings = try await admin.fetchFlaggedListings()
            reports = try await admin.fetchReports()
            users = try await admin.fetchAllUsers()
            transactions = try await txService.fetchAllTransactions()
            let active = try await listingService.fetchActiveListings(cursor: nil)
            _activeListingCount = active.listings.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Moderation actions

    func approveListing(_ listing: Listing) async {
        try? await admin.resolveListing(listingID: listing.id, status: .approved)
        await loadAll()
    }

    func removeListing(_ listing: Listing) async {
        try? await admin.resolveListing(listingID: listing.id, status: .rejected)
        await loadAll()
    }

    func resolveReport(_ report: Report, action: AdminResolution) async {
        try? await admin.resolveReport(reportID: report.id, action: action)
        await loadAll()
    }

    func toggleSuspension(_ user: User) async {
        try? await admin.setUserSuspended(userID: user.id, suspended: !user.isSuspended)
        await loadAll()
    }

    // MARK: - Filters

    func filteredTransactions(status: TransactionStatus?, dateRange: ClosedRange<Date>?) -> [Transaction] {
        transactions.filter { tx in
            if let status, tx.status != status { return false }
            if let window = dateRange, !window.contains(tx.createdAt) { return false }
            return true
        }
    }
}
