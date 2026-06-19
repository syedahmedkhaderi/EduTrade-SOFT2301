import Foundation

/// Listing detail ViewModel (spec §12.8).
@MainActor
final class ListingDetailViewModel: ObservableObject {

    @Published var listing: Listing?
    @Published var seller: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reportReason = ""

    private let listingService: ListingServiceProtocol
    private let adminService: AdminServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.listingService = appState.services.listings
        self.adminService = appState.services.admin
    }

    func load(listingID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let l = try await listingService.fetchListing(id: listingID) {
                listing = l
                if let seller = await appState.services.store.getUser(id: l.sellerID) {
                    self.seller = seller
                    appState.userCache[seller.id] = seller
                }
            } else {
                errorMessage = AppError.notFound.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func report() async -> Bool {
        guard let listing,
              let currentUser = AppState.sessionUser(),
              !reportReason.trimmed.isEmpty else { return false }
        do {
            try await adminService.reportListing(
                listingID: listing.id,
                reporterID: currentUser.id,
                reason: reportReason.trimmed
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
