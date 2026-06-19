import SwiftUI

/// Search screen (spec §4.4, §12.6).
struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = SearchViewModel()
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.hasSearched && vm.results.isEmpty {
                    recentSearchesView
                } else if vm.results.isEmpty && vm.hasSearched && !vm.isLoading {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No results found",
                        subtitle: "Try different keywords or clear filters."
                    )
                    .padding(.top, 80)
                } else {
                    resultList
                }
            }
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
                if vm.isLoading { ProgressView().scaleEffect(1.2).padding() }
                if let error = vm.errorMessage {
                    VStack { ErrorBanner(message: error) { vm.errorMessage = nil }; Spacer() }
                }
            }
        }
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.results) { listing in
                    NavigationLink(value: listing) {
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
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Theme.background)
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if vm.recentSearches.isEmpty {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "Search EduTrade",
                    subtitle: "Find textbooks, lab kits, and notes by title or course code."
                )
                .padding(.top, 60)
            } else {
                HStack {
                    Text("Recent Searches").font(.headline)
                    Spacer()
                    Button("Clear") { vm.clearRecents() }
                        .font(.caption).foregroundStyle(.red)
                }
                ForEach(vm.recentSearches, id: \.self) { term in
                    Button {
                        vm.queryText = term
                        Task { await vm.runSearch(text: term) }
                    } label: {
                        HStack {
                            Image(systemName: "clock").foregroundStyle(Theme.mutedText)
                            Text(term)
                            Spacer()
                            Image(systemName: "arrow.up.left").foregroundStyle(Theme.mutedText)
                        }
                        .padding(.vertical, 6)
                    }
                    .foregroundStyle(.primary)
                }
            }
            Spacer()
        }
        .padding()
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
