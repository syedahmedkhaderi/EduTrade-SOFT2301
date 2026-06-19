import SwiftUI

/// Admin dashboard (spec §4.9, §12.17).
struct AdminDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AdminDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Analytics summary
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(title: "Users", value: "\(vm.totalUsers)", icon: "person.3.fill", color: .blue)
                        statCard(title: "Active Listings", value: "\(vm.totalActiveListings)", icon: "books.vertical.fill", color: .green)
                        statCard(title: "Transactions", value: "\(vm.totalTransactions)", icon: "creditcard.fill", color: .purple)
                        statCard(title: "Commission", value: Formatters.currencyShort(vm.totalCommission), icon: "percent", color: .orange)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        NavigationLink { ModerationQueueView(vm: vm) } label: {
                            adminRow(title: "Moderation Queue", count: vm.flaggedListings.count + vm.reports.count, icon: "flag.fill", color: .red)
                        }
                        NavigationLink { TransactionLogView(vm: vm) } label: {
                            adminRow(title: "Transaction Log", count: vm.transactions.count, icon: "list.bullet.clipboard.fill", color: .blue)
                        }
                        NavigationLink { UserManagementView(vm: vm) } label: {
                            adminRow(title: "User Management", count: vm.users.count, icon: "person.crop.circle.badge.checkmark", color: .green)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationTitle("Admin")
            .task { await vm.loadAll() }
            .refreshable { await vm.loadAll() }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(Theme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func adminRow(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 28)
            Text(title).fontWeight(.medium)
            Spacer()
            Text("\(count)")
                .font(.subheadline.bold())
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(Capsule())
            Image(systemName: "chevron.right").foregroundStyle(Theme.mutedText).font(.caption)
        }
        .padding()
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.primary)
    }
}

// MARK: - Moderation Queue

struct ModerationQueueView: View {
    @ObservedObject var vm: AdminDashboardViewModel

    var body: some View {
        List {
            Section("Flagged Listings") {
                if vm.flaggedListings.isEmpty {
                    Text("No flagged listings").foregroundStyle(Theme.mutedText)
                }
                ForEach(vm.flaggedListings) { listing in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(listing.title).font(.subheadline.bold())
                            Spacer()
                            Label("Flagged", systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.red)
                        }
                        Text(listing.description).font(.caption).foregroundStyle(Theme.mutedText).lineLimit(2)
                        HStack(spacing: 8) {
                            Button("Approve") { Task { await vm.approveListing(listing) } }
                                .buttonStyle(.borderedProminent).tint(.green)
                            Button("Remove", role: .destructive) { Task { await vm.removeListing(listing) } }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Section("User Reports") {
                if vm.reports.isEmpty {
                    Text("No open reports").foregroundStyle(Theme.mutedText)
                }
                ForEach(vm.reports) { report in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(report.reason).font(.subheadline)
                        Text(Formatters.relativeDate(report.createdAt)).font(.caption).foregroundStyle(Theme.mutedText)
                        HStack(spacing: 8) {
                            Button("Approve Listing") { Task { await vm.resolveReport(report, action: .approveListing) } }
                                .buttonStyle(.borderedProminent).tint(.green)
                            Button("Remove Listing", role: .destructive) { Task { await vm.resolveReport(report, action: .removeListing) } }
                                .buttonStyle(.bordered)
                            Button("Dismiss") { Task { await vm.resolveReport(report, action: .dismissReport) } }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .navigationTitle("Moderation Queue")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Transaction Log

struct TransactionLogView: View {
    @ObservedObject var vm: AdminDashboardViewModel
    @State private var statusFilter: TransactionStatus? = nil

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag(TransactionStatus?.none)
                    ForEach(TransactionStatus.allCases, id: \.self) { Text($0.rawValue.capitalized).tag(Optional($0)) }
                }
            }
            ForEach(filteredTransactions, id: \.id) { tx in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Transaction #\(tx.id.prefix(8))").font(.subheadline.bold())
                        Spacer()
                        Text(tx.status.rawValue.capitalized).font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(statusColor(tx.status).opacity(0.15))
                            .foregroundStyle(statusColor(tx.status))
                            .clipShape(Capsule())
                    }
                    HStack {
                        Label(Formatters.currency(tx.itemPrice), systemImage: "creditcard")
                        Spacer()
                        Label(Formatters.currency(tx.commissionAmount), systemImage: "percent")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                    Text(Formatters.dateTime(tx.createdAt)).font(.caption2).foregroundStyle(Theme.mutedText)
                }
            }
        }
        .navigationTitle("Transaction Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredTransactions: [Transaction] {
        guard let status = statusFilter else { return vm.transactions }
        return vm.transactions.filter { $0.status == status }
    }

    private func statusColor(_ status: TransactionStatus) -> Color {
        switch status {
        case .completed: return .green
        case .pending:   return .orange
        case .refunded:  return .blue
        case .disputed:  return .red
        }
    }
}

// MARK: - User Management

struct UserManagementView: View {
    @ObservedObject var vm: AdminDashboardViewModel
    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(filteredUsers) { user in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Theme.accentColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Text(user.fullName.initials).font(.caption.bold()).foregroundStyle(Theme.accentColor))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullName).font(.subheadline.bold())
                        Text(user.universityEmail).font(.caption).foregroundStyle(Theme.mutedText)
                    }
                    Spacer()
                    if user.isSuspended {
                        Label("Suspended", systemImage: "person.badge.minus")
                            .font(.caption).foregroundStyle(.red)
                    }
                    if user.isAdmin {
                        Label("Admin", systemImage: "shield")
                            .font(.caption).foregroundStyle(Theme.accentColor)
                    }
                    if !user.isAdmin {
                        Toggle("", isOn: Binding(
                            get: { !user.isSuspended },
                            set: { active in Task { await vm.toggleSuspension(user) } }
                        ))
                        .labelsHidden()
                        .tint(Theme.accentColor)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search users…")
        .navigationTitle("Users")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredUsers: [User] {
        guard !searchText.isEmpty else { return vm.users }
        return vm.users.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.universityEmail.localizedCaseInsensitiveContains(searchText)
        }
    }
}
