import SwiftUI

/// Profile tab (spec §12.12).
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ProfileViewModel()
    let user: User

    var body: some View {
        NavigationStack {
            List {
                // Header
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Theme.accentColor.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(user.fullName.initials).font(.title2.bold()).foregroundStyle(Theme.accentColor)
                            )
                        VStack(alignment: .leading, spacing: 6) {
                            Text(user.fullName).font(.title3.bold())
                            Text(user.universityEmail).font(.caption).foregroundStyle(Theme.mutedText)
                            StarRatingView(rating: user.averageRating, totalRatings: user.totalRatings, size: 13)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    NavigationLink {
                        MyListingsView(vm: vm)
                    } label: {
                        Label("My Listings", systemImage: "square.grid.2x2.fill")
                    }
                    NavigationLink {
                        OrderHistoryView(vm: vm)
                    } label: {
                        Label("Order History", systemImage: "bag.fill")
                    }
                    NavigationLink {
                        EditProfileView(user: user)
                    } label: {
                        Label("Edit Profile", systemImage: "person.crop.square")
                    }
                }

                Section {
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                }

                if user.isAdmin {
                    Section {
                        Label("Admin Dashboard", systemImage: "shield.lefthalf.filled")
                            .foregroundStyle(Theme.accentColor)
                    } header: { Text("Administration") }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await AuthViewModel().signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await vm.loadAll() }
        }
    }
}

// MARK: - My Listings

struct MyListingsView: View {
    @ObservedObject var vm: ProfileViewModel
    @State private var selectedSegment = 0

    var body: some View {
        List {
            Picker("Filter", selection: $selectedSegment) {
                Text("Active").tag(0)
                Text("Sold").tag(1)
                Text("Draft").tag(2)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            ForEach(currentList) { listing in
                HStack(spacing: 12) {
                    ListingImage(imageKey: listing.imageURLs.first, title: listing.title, cornerRadius: 8)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title).font(.subheadline.bold()).lineLimit(2)
                        Text(Formatters.currency(listing.price)).foregroundStyle(Theme.accentColor).fontWeight(.semibold)
                    }
                    Spacer()
                    if selectedSegment == 0 {
                        Menu {
                            Button("Mark as Sold", systemImage: "checkmark") {
                                Task { await vm.markAsSold(listing.id) }
                            }
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                Task { await vm.deleteListing(listing.id) }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle("My Listings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentList: [Listing] {
        switch selectedSegment {
        case 0: return vm.activeListings
        case 1: return vm.soldListings
        default: return vm.draftListings
        }
    }
}

// MARK: - Order History

struct OrderHistoryView: View {
    @ObservedObject var vm: ProfileViewModel
    @State private var selectedSegment = 0

    var body: some View {
        List {
            Picker("Filter", selection: $selectedSegment) {
                Text("Purchases").tag(0)
                Text("Sales").tag(1)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            ForEach(currentTransactions, id: \.id) { tx in
                NavigationLink {
                    RateTransactionView(transaction: tx)
                } label: {
                    TransactionRow(transaction: tx)
                }
            }
        }
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentTransactions: [Transaction] {
        selectedSegment == 0 ? vm.purchases : vm.sales
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transaction #\(transaction.id.prefix(8))").font(.subheadline.bold())
                Text(Formatters.date(transaction.createdAt))
                    .font(.caption).foregroundStyle(Theme.mutedText)
                Text(Formatters.currency(transaction.itemPrice))
                    .foregroundStyle(Theme.accentColor).fontWeight(.semibold)
            }
            Spacer()
            statusBadge
        }
    }

    @ViewBuilder private var statusBadge: some View {
        switch transaction.status {
        case .completed:
            Label("Completed", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Theme.success)
        case .pending:
            Label("Pending", systemImage: "clock.fill").font(.caption).foregroundStyle(.orange)
        case .refunded:
            Label("Refunded", systemImage: "arrow.uturn.backward.circle.fill").font(.caption).foregroundStyle(.blue)
        case .disputed:
            Label("Disputed", systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.red)
        }
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    let user: User
    @State private var fullName: String = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("Full Name", text: $fullName)
            }
            Section {
                Text(user.universityEmail).foregroundStyle(Theme.mutedText)
            } header: { Text("Email (not editable)") }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fullName = user.fullName }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = user
                    updated.fullName = fullName
                    saved = true
                }
            }
        }
    }
}

// MARK: - Language

struct LanguageSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases) { lang in
                    HStack {
                        Text(lang.displayName)
                        Spacer()
                        if appState.preferredLanguage == lang {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.setLanguage(lang)
                    }
                }
            } footer: {
                Text("Changing the language updates the layout direction (RTL for Arabic). Restart the app for full localization to take effect.")
                    .font(.caption)
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
