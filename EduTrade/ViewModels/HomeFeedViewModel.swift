import Foundation

/// Home feed ViewModel (spec §12.5).
@MainActor
final class HomeFeedViewModel: ObservableObject {

    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasReachedEnd = false

    private var cursor: String?
    private let service: ListingServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.service = appState.services.listings
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        cursor = nil
        hasReachedEnd = false
        do {
            let page = try await service.fetchActiveListings(cursor: nil)
            listings = page.listings
            cursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            await cacheSellers(page.listings)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, !hasReachedEnd, let cursor else { return }
        isLoadingMore = true
        do {
            let page = try await service.fetchActiveListings(cursor: cursor)
            listings.append(contentsOf: page.listings)
            self.cursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            await cacheSellers(page.listings)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    func refresh() async {
        await loadInitial()
    }

    private func cacheSellers(_ listings: [Listing]) async {
        let ids = Set(listings.map { $0.sellerID })
        for id in ids where appState.userCache[id] == nil {
            if let user = await appState.services.store.getUser(id: id) {
                appState.userCache[id] = user
            }
        }
    }
}
