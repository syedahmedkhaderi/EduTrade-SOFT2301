import SwiftUI

/// Listing detail screen (spec §12.8).
struct ListingDetailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ListingDetailViewModel()

    let listingID: String

    @State private var showCheckout = false
    @State private var showReportSheet = false
    @State private var currentImageIndex = 0

    var body: some View {
        ScrollView {
            if let listing = vm.listing {
                VStack(alignment: .leading, spacing: 16) {
                    // Photo carousel
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array(listing.imageURLs.indices), id: \.self) { idx in
                            ListingImage(imageKey: listing.imageURLs[idx], title: listing.title, cornerRadius: 0)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 300)
                    .background(Theme.card)

                    VStack(alignment: .leading, spacing: 16) {
                        // Title + price
                        VStack(alignment: .leading, spacing: 6) {
                            Text(listing.title)
                                .font(.title2.bold())
                            Text(Formatters.currency(listing.price))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.accentColor)
                        }

                        // Tags row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ConditionTagView(condition: listing.condition)
                                tagChip(icon: "graduationcap", text: listing.courseCode)
                                tagChip(icon: "books.vertical", text: listing.subject)
                            }
                        }

                        Divider()

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description").font(.headline)
                            Text(listing.description)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }

                        Divider()

                        // Seller snippet
                        if let seller = vm.seller {
                            SellerProfileSnippetView(seller: seller)
                        }

                        Divider()

                        // Meta
                        HStack {
                            Label(Formatters.relativeDate(listing.createdAt), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            Spacer()
                            if listing.status == .sold {
                                Label("Sold", systemImage: "checkmark.seal.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = vm.errorMessage {
                EmptyStateView(symbol: "exclamationmark.triangle", title: "Error", subtitle: error)
                    .padding(.top, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showReportSheet = true } label: {
                    Image(systemName: "flag")
                }
                .accessibilityLabel("Report listing")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let listing = vm.listing, listing.status != .sold {
                checkoutBar(listing: listing)
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            if let listing = vm.listing {
                CheckoutView(listingID: listing.id)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(vm: vm) { Task { _ = await vm.report() } }
        }
        .task { await vm.load(listingID: listingID) }
    }

    private func checkoutBar(listing: Listing) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total").font(.caption).foregroundStyle(Theme.mutedText)
                Text(Formatters.currency(listing.price))
                    .font(.headline.bold())
            }
            Spacer()
            Button {
                showCheckout = true
            } label: {
                Label("Buy Now", systemImage: "creditcard.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.bar)
    }

    private func tagChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Theme.accentColor.opacity(0.12))
        .foregroundStyle(Theme.accentColor)
        .clipShape(Capsule())
    }
}

/// Seller snippet (spec §12.8).
struct SellerProfileSnippetView: View {
    let seller: User

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.accentColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(seller.fullName.initials)
                        .font(.headline)
                        .foregroundStyle(Theme.accentColor)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(seller.fullName).font(.subheadline.bold())
                StarRatingView(rating: seller.averageRating, totalRatings: seller.totalRatings, size: 12)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ReportSheet: View {
    @ObservedObject var vm: ListingDetailViewModel
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Why are you reporting this listing?") {
                    ForEach([
                        "Prohibited or illegal item",
                        "Spam or scam",
                        "Inappropriate content",
                        "Counterfeit item",
                        "Other"
                    ], id: \.self) { reason in
                        Button(reason) {
                            vm.reportReason = reason
                        }
                        .foregroundStyle(.primary)
                    }
                }
                if !vm.reportReason.isEmpty {
                    Section("Selected reason") {
                        Text(vm.reportReason).foregroundStyle(Theme.mutedText)
                    }
                }
            }
            .navigationTitle("Report Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.reportReason = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { onSubmit() }
                        .disabled(vm.reportReason.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

extension String {
    var initials: String {
        split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    }
}
