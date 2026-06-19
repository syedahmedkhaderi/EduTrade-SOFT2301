import Foundation

/// Search + filter ViewModel (spec §4.4, §12.6, §12.7).
@MainActor
final class SearchViewModel: ObservableObject {

    @Published var queryText = ""
    @Published var results: [Listing] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var errorMessage: String?

    // Filter state (bound to FilterSheetView)
    @Published var filterSubject: String? = nil
    @Published var filterCourseCode = ""
    @Published var filterMinPrice: Double = 0
    @Published var filterMaxPrice: Double = 1000
    @Published var filterConditions: Set<Condition> = []
    @Published var filtersApplied = false

    @Published var recentSearches: [String] = []
    @Published var trendingListings: [Listing] = []
    @Published var categoryCounts: [(subject: String, count: Int)] = []

    private let service: ListingServiceProtocol
    private let appState: AppState
    private var debounceTask: Task<Void, Never>?

    private let recentsKey = Constants.UserDefaultsKeys.recentSearches

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.service = appState.services.listings
        loadRecents()
    }

    var hasActiveFilters: Bool {
        filterSubject != nil || !filterCourseCode.isEmpty ||
        filterConditions.count > 0 || filtersApplied
    }

    // MARK: - Discovery feed (recommendations shown when search is empty)

    func loadDiscoveryFeed() async {
        // Fetch all active listings for discovery
        if let page = try? await service.fetchActiveListings(cursor: nil) {
            trendingListingsFullList = page.listings
            // Recommended deals = cheapest items (value picks for students)
            trendingListings = page.listings
                .sorted { $0.price < $1.price }
                .prefix(6)
                .map { $0 }
            await cacheSellers(trendingListings)
        }
        // Popular categories = count listings per subject
        var counts: [(String, Int)] = []
        for subject in Constants.subjects {
            let count = trendingListingsFullList.filter { $0.subject == subject }.count
            if count > 0 { counts.append((subject, count)) }
        }
        categoryCounts = counts.sorted { $0.1 > $1.1 }.prefix(6).map { ($0.0, $0.1) }
    }

    /// Cached full active listing list for category counting.
    private var trendingListingsFullList: [Listing] = []

    func searchByCategory(_ subject: String) async {
        filterSubject = subject
        filtersApplied = true
        queryText = ""
        await runSearch(text: subject)
    }

    func searchBySuggestion(_ term: String) async {
        queryText = term
        await runSearch(text: term)
    }

    // MARK: - Debounced search

    func onQueryChange() {
        debounceTask?.cancel()
        let snapshot = queryText
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            if snapshot.trimmed.isEmpty {
                results = []
                hasSearched = false
            } else {
                await runSearch(text: snapshot)
            }
        }
    }

    func runSearch(text: String? = nil) async {
        let q = (text ?? queryText).trimmed
        guard !q.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let query = SearchQuery(
            text: q,
            subject: filterSubject,
            courseCode: filterCourseCode.trimmed.isEmpty ? nil : filterCourseCode.trimmed,
            minPrice: filtersApplied ? filterMinPrice : nil,
            maxPrice: filtersApplied ? filterMaxPrice : nil,
            conditions: Array(filterConditions)
        )
        do {
            let page = try await service.searchListings(query: query)
            results = page.listings
            hasSearched = true
            saveRecent(q)
            await cacheSellers(page.listings)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetFilters() {
        filterSubject = nil
        filterCourseCode = ""
        filterMinPrice = 0
        filterMaxPrice = 1000
        filterConditions = []
        filtersApplied = false
        if hasSearched { Task { await runSearch() } }
    }

    func applyFilters() {
        filtersApplied = true
        Task { await runSearch() }
    }

    // MARK: - Recents

    private func loadRecents() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
    }

    private func saveRecent(_ term: String) {
        var list = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
        list.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        list.insert(term, at: 0)
        if list.count > 8 { list = Array(list.prefix(8)) }
        UserDefaults.standard.set(list, forKey: recentsKey)
        recentSearches = list
    }

    func clearRecents() {
        UserDefaults.standard.removeObject(forKey: recentsKey)
        recentSearches = []
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
