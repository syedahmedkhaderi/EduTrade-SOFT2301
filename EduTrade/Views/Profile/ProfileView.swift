import SwiftUI

/// Profile tab (spec §12.12).
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ProfileViewModel()
    let user: User

    var body: some View {
        NavigationStack {
            List {
                // Profile header with avatar + name + rating
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Theme.accentColor.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(user.fullName.initials)
                                    .font(.title2.bold())
                                    .foregroundStyle(Theme.accentColor)
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

                // Stats row
                Section {
                    HStack(spacing: 0) {
                        statItem(value: "\(vm.activeListings.count)", label: "Active", icon: "square.grid.2x2")
                        Divider().frame(height: 36)
                        statItem(value: "\(vm.sales.count)", label: "Sold", icon: "checkmark.seal")
                        Divider().frame(height: 36)
                        statItem(value: "\(vm.purchases.count)", label: "Bought", icon: "bag")
                        Divider().frame(height: 36)
                        statItem(value: String(format: "%.1f", user.averageRating), label: "Rating", icon: "star")
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }

                // My Activity
                Section("My Activity") {
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
                        SavedListingsView(vm: vm)
                    } label: {
                        Label("Saved Items", systemImage: "bookmark.fill")
                    }
                }

                // Account
                Section("Account") {
                    NavigationLink {
                        EditProfileView(user: user)
                    } label: {
                        Label("Edit Profile", systemImage: "person.crop.square")
                    }
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                // About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About EduTrade", systemImage: "info.circle")
                    }
                    NavigationLink {
                        HelpCenterView()
                    } label: {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    NavigationLink {
                        TermsView()
                    } label: {
                        Label("Terms & Privacy", systemImage: "doc.text")
                    }
                }

                if user.isAdmin {
                    Section("Administration") {
                        Label("Admin Dashboard — see Admin tab", systemImage: "shield.lefthalf.filled")
                            .foregroundStyle(Theme.accentColor)
                    }
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
            .refreshable { await vm.loadAll() }
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Theme.accentColor)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(Theme.mutedText)
        }
        .frame(maxWidth: .infinity)
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

            if currentList.isEmpty {
                EmptyStateView(
                    symbol: "square.dashed",
                    title: "No \(selectedSegment == 0 ? "active" : selectedSegment == 1 ? "sold" : "draft") listings",
                    subtitle: "Items you list will appear here."
                )
                .padding(.top, 40)
                .listRowBackground(Color.clear)
            } else {
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

// MARK: - Saved Listings

struct SavedListingsView: View {
    @ObservedObject var vm: ProfileViewModel

    var body: some View {
        Group {
            if vm.savedListings.isEmpty {
                EmptyStateView(
                    symbol: "bookmark",
                    title: "No saved items",
                    subtitle: "Tap the bookmark icon on any listing to save it for later."
                )
                .padding(.top, 60)
            } else {
                List {
                    ForEach(vm.savedListings) { listing in
                        NavigationLink {
                            ListingDetailView(listingID: listing.id)
                        } label: {
                            HStack(spacing: 12) {
                                ListingImage(imageKey: listing.imageURLs.first, title: listing.title, cornerRadius: 8)
                                    .frame(width: 56, height: 56)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(listing.title).font(.subheadline.bold()).lineLimit(2)
                                    Text(Formatters.currency(listing.price))
                                        .foregroundStyle(Theme.accentColor).fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Items")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadSavedListings() }
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

            if currentTransactions.isEmpty {
                EmptyStateView(
                    symbol: "bag",
                    title: "No \(selectedSegment == 0 ? "purchases" : "sales") yet",
                    subtitle: "Your transaction history will appear here."
                )
                .padding(.top, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(currentTransactions, id: \.id) { tx in
                    NavigationLink {
                        RateTransactionView(transaction: tx)
                    } label: {
                        TransactionRow(transaction: tx)
                    }
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
    @EnvironmentObject var appState: AppState
    let user: User
    @State private var fullName: String = ""
    @State private var savedToast = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("Full Name", text: $fullName)
            }
            Section {
                Text(user.universityEmail).foregroundStyle(Theme.mutedText)
            } header: { Text("Email") } footer: {
                Text("Your university email cannot be changed after verification.")
            }
            Section("Account Info") {
                LabeledContent("Member Since", value: Formatters.date(user.createdAt))
                LabeledContent("Account Type", value: user.isAdmin ? "Administrator" : "Student")
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fullName = user.fullName }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveProfile() }
                }
                .disabled(fullName.trimmed.isEmpty || fullName == user.fullName)
            }
        }
    }

    private func saveProfile() async {
        var updated = user
        updated.fullName = fullName.trimmed
        await appState.services.store.upsertUser(updated)
        appState.applyUser(updated)
        appState.toasts.success("Profile updated!")
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("emailNotifications") private var emailNotifications = true
    @AppStorage("priceAlerts") private var priceAlerts = false

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                Toggle("Email Updates", isOn: $emailNotifications)
                Toggle("Price Drop Alerts", isOn: $priceAlerts)
            }
            Section {
                Button("Reset Demo Data", role: .destructive) {
                    appState.services.resetMockData()
                    appState.toasts.info("Demo data has been reset. Relaunch the app.")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("This restores all listings, users, and transactions to their original seeded state.")
            }
            Section("Legal") {
                NavigationLink {
                    TermsView()
                } label: {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                NavigationLink {
                    PrivacyView()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Text("EduTrade").font(.title.bold())
                Text("Version 1.0").font(.caption).foregroundStyle(Theme.mutedText)

                VStack(alignment: .leading, spacing: 16) {
                    aboutRow(icon: "graduationcap.fill", title: "Built for UDST",
                             text: "EduTrade is a peer-to-peer marketplace exclusively for University of Doha for Science and Technology students.")
                    aboutRow(icon: "handshake.fill", title: "Buy & Sell",
                             text: "List textbooks, lab kits, and notes. Browse by course code or subject. Secure payments with 10% platform fee.")
                    aboutRow(icon: "shield.fill", title: "Verified & Trusted",
                             text: "All users verify with their @udst.edu.qa email. Rate transactions to build trust in the community.")
                    aboutRow(icon: "globe", title: "Bilingual",
                             text: "Full English and Arabic support with automatic right-to-left layout.")
                }
                .padding()
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Course Project — SOFT2301")
                    .font(.caption).foregroundStyle(Theme.mutedText)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentColor)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.caption).foregroundStyle(Theme.mutedText)
            }
        }
    }
}

// MARK: - Help Center

struct HelpCenterView: View {
    var body: some View {
        Form {
            Section("Getting Started") {
                helpItem(question: "How do I create a listing?",
                         answer: "Tap the Sell tab, upload photos, fill in details, and publish. Your listing is live immediately after moderation.")
                helpItem(question: "How do I buy an item?",
                         answer: "Browse listings, tap Buy Now, and complete checkout. The 10% platform fee is added transparently.")
                helpItem(question: "How does payment work?",
                         answer: "Payments are processed securely. The seller receives 90% and EduTrade collects a 10% commission.")
            }
            Section("Account") {
                helpItem(question: "Why only @udst.edu.qa emails?",
                         answer: "EduTrade is exclusive to UDST students for trust and safety.")
                helpItem(question: "How do ratings work?",
                         answer: "After each transaction, both buyer and seller can rate each other from 1 to 5 stars.")
            }
            Section("Contact") {
                Link(destination: URL(string: "mailto:support@edutrade.qa")!) {
                    Label("Email Support", systemImage: "envelope")
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpItem(question: String, answer: String) -> some View {
        DisclosureGroup(question) {
            Text(answer).font(.subheadline).foregroundStyle(Theme.mutedText)
        }
        .font(.subheadline)
    }
}

// MARK: - Terms & Privacy

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                legalSection(title: "Terms of Service",
                    body: "EduTrade is a platform connecting UDST students for the purpose of buying and selling used academic materials. Users must be verified UDST students. EduTrade charges a 10% commission on each completed transaction. Prohibited items include illegal goods, weapons, drugs, counterfeit items, and academic dishonesty materials. Listings violating these terms are removed.")
                legalSection(title: "User Responsibilities",
                    body: "Sellers must accurately describe items including condition and any damage. Buyers should review listings carefully before purchasing. Both parties are encouraged to rate transactions to maintain platform trust.")
                Divider()
                Text("Last updated: June 2026").font(.caption2).foregroundStyle(Theme.mutedText)
            }
            .padding()
        }
        .navigationTitle("Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                legalSection(title: "Privacy Policy",
                    body: "EduTrade collects your university email, name, and listing data to operate the platform. Payment information is processed securely and not stored on our servers. Your data is never shared with third parties. You can request data deletion by contacting support.")
                legalSection(title: "Data Security",
                    body: "Authentication tokens are stored in the iOS Keychain. All network communication is encrypted. Payment processing uses industry-standard security through our payment gateway partner.")
                Divider()
                Text("Last updated: June 2026").font(.caption2).foregroundStyle(Theme.mutedText)
            }
            .padding()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func legalSection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title).font(.headline)
        Text(body).font(.subheadline).foregroundStyle(Theme.mutedText)
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
