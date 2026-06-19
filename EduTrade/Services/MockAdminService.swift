import Foundation

/// Mock admin service.
final class MockAdminService: AdminServiceProtocol {

    private let store: MockStore
    init(store: MockStore) { self.store = store }

    func fetchReports() async throws -> [Report] {
        await store.reports.filter { $0.status == .open }.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchFlaggedListings() async throws -> [Listing] {
        await store.listings.filter { $0.moderationStatus == .flagged }.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchAllUsers() async throws -> [User] {
        await store.users.sorted { $0.createdAt < $1.createdAt }
    }

    func resolveReport(reportID: String, action: AdminResolution) async throws {
        guard var report = await store.reports.first(where: { $0.id == reportID }) else { return }
        switch action {
        case .approveListing:
            report.status = .resolved
        case .removeListing:
            report.status = .resolved
            if var listing = await store.getListing(id: report.listingID) {
                listing.status = .removed
                listing.moderationStatus = .rejected
                listing.updatedAt = .now
                await store.upsertListing(listing)
            }
        case .dismissReport:
            report.status = .dismissed
        }
        await store.upsertReport(report)
    }

    func resolveListing(listingID: String, status: ModerationStatus) async throws {
        guard var listing = await store.getListing(id: listingID) else { return }
        listing.moderationStatus = status
        listing.updatedAt = .now
        if status == .rejected { listing.status = .removed }
        await store.upsertListing(listing)
    }

    func setUserSuspended(userID: String, suspended: Bool) async throws {
        guard var user = await store.getUser(id: userID) else { return }
        user.isSuspended = suspended
        await store.upsertUser(user)
    }

    func reportListing(listingID: String, reporterID: String, reason: String) async throws {
        let report = Report(listingID: listingID, reporterID: reporterID, reason: reason)
        await store.upsertReport(report)
    }
}
