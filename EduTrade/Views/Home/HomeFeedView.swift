import SwiftUI

/// Home feed (spec §12.5).
struct HomeFeedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeFeedViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading && vm.listings.isEmpty {
                    loadingState
                } else if vm.listings.isEmpty {
                    EmptyStateView(
                        symbol: "books.vertical",
                        title: "No listings yet",
                        subtitle: "Be the first to sell something on EduTrade."
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(vm.listings) { listing in
                            NavigationLink(value: listing) {
                                ListingCardView(
                                    listing: listing,
                                    sellerRating: appState.userCache[listing.sellerID]?.averageRating ?? 0,
                                    sellerTotalRatings: appState.userCache[listing.sellerID]?.totalRatings ?? 0
                                )
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if listing.id == vm.listings.last?.id {
                                    Task { await vm.loadMore() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if vm.isLoadingMore {
                        ProgressView().padding()
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("EduTrade")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: .constant(""), prompt: "Search textbooks, course codes…")
            .onSubmit(of: .search) {
                appState.tabSelection = 1
            }
            .refreshable { await vm.refresh() }
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(listingID: listing.id)
            }
            .task {
                if vm.listings.isEmpty { await vm.loadInitial() }
            }
            .overlay {
                if let error = vm.errorMessage {
                    VStack {
                        ErrorBanner(message: error) { vm.errorMessage = nil }
                        Spacer()
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Theme.card)
                    .frame(height: 220)
                    .overlay(ProgressView())
            }
        }
        .padding()
    }
}
