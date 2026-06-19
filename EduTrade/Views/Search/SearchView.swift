import SwiftUI

/// Search screen with discovery feed, recommendations, and filters (spec §4.4, §12.6).
struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = SearchViewModel()
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.results.isEmpty {
                    ProgressView().padding(.top, 60)
                } else if vm.hasSearched && vm.results.isEmpty && !vm.isLoading {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No results found",
                        subtitle: "Try different keywords or clear filters."
                    )
                    .padding(.top, 60)
                } else if vm.hasSearched && !vm.results.isEmpty {
                    resultList
                } else {
                    discoveryFeed
                }
            }
            .background(Theme.background)
            .navigationTitle("Search")
            .searchable(text: $vm.queryText, prompt: "Search by title or course code…")
            .onChange(of: vm.queryText) { _, _ in vm.onQueryChange() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: vm.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(vm: vm)
            }
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(listingID: listing.id)
            }
            .overlay {
                if let error = vm.errorMessage {
                    VStack { ErrorBanner(message: error) { vm.errorMessage = nil }; Spacer() }
                }
            }
            .task {
                if vm.trendingListings.isEmpty {
                    await vm.loadDiscoveryFeed()
                }
            }
            .refreshable {
                await vm.loadDiscoveryFeed()
            }
        }
    }

    // MARK: - Discovery Feed (shown when no search active)

    private var discoveryFeed: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Quick suggestions
            suggestionChips

            // Popular categories
            if !vm.categoryCounts.isEmpty {
                sectionHeader(title: "Popular Categories", icon: "square.grid.2x2.fill")
                categoryGrid
            }

            // Recommended deals
            if !vm.trendingListings.isEmpty {
                sectionHeader(title: "Recommended Deals", icon: "tag.fill")
                trendingDealsCarousel
            }

            // Recent searches
            if !vm.recentSearches.isEmpty {
                sectionHeader(title: "Recent Searches", icon: "clock.fill")
                recentSearchesList
            }

            // Footer tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill").foregroundStyle(.orange)
                Text("Tip: Search by course code (e.g. SOFT1101) to find exact materials for your classes.")
                    .font(.caption).foregroundStyle(Theme.mutedText)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Textbooks", "Notes", "Lab Kits", "SOFT", "MATH", "Engineering"], id: \.self) { term in
                    Button {
                        Task { await vm.searchBySuggestion(term) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: term.count <= 5 ? "magnifyingglass" : "book")
                                .font(.system(size: 10))
                            Text(term).font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.accentColor.opacity(0.1))
                        .foregroundStyle(Theme.accentColor)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(Theme.accentColor)
            Text(title).font(.headline)
            Spacer()
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(vm.categoryCounts, id: \.subject) { cat in
                Button {
                    Task { await vm.searchByCategory(cat.subject) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cat.subject).font(.subheadline.weight(.semibold))
                            Text("\(cat.count) item\(cat.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(Theme.mutedText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(Theme.mutedText)
                    }
                    .padding(12)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private var trendingDealsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.trendingListings) { listing in
                    NavigationLink(value: listing) {
                        VStack(alignment: .leading, spacing: 0) {
                            ListingImage(imageKey: listing.imageURLs.first, title: listing.title, cornerRadius: 0)
                                .frame(width: 130, height: 130)
                                .clipped()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.title).font(.caption.weight(.semibold)).lineLimit(2)
                                Text(Formatters.currency(listing.price))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.accentColor)
                            }
                            .padding(8)
                            .frame(width: 130, alignment: .leading)
                        }
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentSearchesList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(vm.recentSearches, id: \.self) { term in
                Button {
                    Task { await vm.searchBySuggestion(term) }
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.mutedText)
                        Text(term).font(.subheadline)
                        Spacer()
                        Image(systemName: "arrow.up.left").foregroundStyle(Theme.mutedText)
                    }
                    .padding(.vertical, 8)
                }
                .foregroundStyle(.primary)
            }
            Button {
                vm.clearRecents()
            } label: {
                Text("Clear recent searches").font(.caption).foregroundStyle(.red)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Search Results

    private var resultList: some View {
        LazyVStack(spacing: 12) {
            if vm.hasActiveFilters {
                HStack {
                    Text("\(vm.results.count) result\(vm.results.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(Theme.mutedText)
                    Spacer()
                    Button("Clear filters") {
                        vm.resetFilters()
                    }
                    .font(.caption.weight(.medium)).foregroundStyle(Theme.accentColor)
                }
                .padding(.horizontal, 4)
            }
            ForEach(vm.results) { listing in
                NavigationLink(value: listing) {
                    searchResultRow(listing)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .padding(.bottom, 20)
    }

    private func searchResultRow(_ listing: Listing) -> some View {
        HStack(spacing: 12) {
            ListingImage(imageKey: listing.imageURLs.first, title: listing.title, cornerRadius: 10)
                .frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title).font(.subheadline.bold()).lineLimit(2)
                HStack(spacing: 4) {
                    Text(listing.courseCode).font(.caption).foregroundStyle(Theme.mutedText)
                    Text("·").foregroundStyle(Theme.mutedText)
                    Text(listing.subject).font(.caption).foregroundStyle(Theme.mutedText)
                }
                HStack {
                    Text(Formatters.currency(listing.price))
                        .font(.headline).foregroundStyle(Theme.accentColor)
                    Spacer()
                    ConditionTagView(condition: listing.condition)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Filter sheet (spec §12.7).
struct FilterSheetView: View {
    @ObservedObject var vm: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject") {
                    Picker("Subject", selection: $vm.filterSubject) {
                        Text("Any").tag(String?.none)
                        ForEach(Constants.subjects, id: \.self) { Text($0).tag(Optional($0)) }
                    }
                }

                Section("Course Code") {
                    TextField("e.g. SOFT1101", text: $vm.filterCourseCode)
                        .autocapitalization(.allCharacters)
                }

                Section("Price Range") {
                    VStack(alignment: .leading) {
                        Text("\(Formatters.currencyShort(vm.filterMinPrice)) – \(Formatters.currencyShort(vm.filterMaxPrice))")
                            .font(.caption).foregroundStyle(Theme.mutedText)
                        HStack {
                            Text("Min")
                            Slider(value: $vm.filterMinPrice, in: 0...1000, step: 10)
                            Text("Max")
                        }
                        Slider(value: $vm.filterMaxPrice, in: 0...1000, step: 10)
                    }
                }

                Section("Condition") {
                    ForEach(Condition.allCases) { condition in
                        Toggle(condition.displayName, isOn: Binding(
                            get: { vm.filterConditions.contains(condition) },
                            set: { isOn in
                                if isOn { vm.filterConditions.insert(condition) }
                                else    { vm.filterConditions.remove(condition) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { vm.resetFilters() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        vm.applyFilters()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
