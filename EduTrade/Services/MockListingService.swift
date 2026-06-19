import Foundation

/// Mock listing service backed by MockStore.
final class MockListingService: ListingServiceProtocol {

    private let store: MockStore
    init(store: MockStore) { self.store = store }

    func fetchActiveListings(cursor: String?) async throws -> ListingPage {
        let all = await store.listings
            .filter { $0.status == .active && $0.moderationStatus.isPubliclyVisible }
            .sorted { $0.createdAt > $1.createdAt }
        return paginate(all, cursor: cursor)
    }

    func fetchListing(id: String) async throws -> Listing? {
        await store.getListing(id: id)
    }

    func fetchListings(bySeller sellerID: String, includeSold: Bool) async throws -> [Listing] {
        await store.listings
            .filter { $0.sellerID == sellerID && (includeSold ? true : $0.status != .removed) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createListing(_ listing: Listing) async throws -> Listing {
        var created = listing
        created.moderationStatus = moderationCheck(title: listing.title, description: listing.description)
        created.updatedAt = .now
        await store.upsertListing(created)
        return created
    }

    func updateListing(_ listing: Listing) async throws -> Listing {
        var updated = listing
        updated.updatedAt = .now
        await store.upsertListing(updated)
        return updated
    }

    func deleteListing(id: String) async throws {
        let snapshot = await store.listings
        for listing in snapshot where listing.id == id {
            var removed = listing
            removed.status = .removed
            await store.upsertListing(removed)
        }
    }

    func markAsSold(id: String) async throws {
        guard var listing = await store.getListing(id: id) else { return }
        listing.status = .sold
        listing.updatedAt = .now
        await store.upsertListing(listing)
    }

    func searchListings(query: SearchQuery) async throws -> ListingPage {
        let all = await store.listings
            .filter { $0.status == .active && $0.moderationStatus.isPubliclyVisible }

        var filtered = all

        if let text = query.text?.trimmed.lowercased(), !text.isEmpty {
            filtered = filtered.filter { listing in
                listing.title.lowercased().contains(text) ||
                listing.courseCode.lowercased().contains(text) ||
                listing.subject.lowercased().contains(text) ||
                listing.description.lowercased().contains(text)
            }
        }
        if let subject = query.subject, !subject.isEmpty {
            filtered = filtered.filter { $0.subject == subject }
        }
        if let course = query.courseCode?.trimmed, !course.isEmpty {
            filtered = filtered.filter { $0.courseCode.lowercased().contains(course.lowercased()) }
        }
        if let min = query.minPrice {
            filtered = filtered.filter { $0.price >= min }
        }
        if let max = query.maxPrice {
            filtered = filtered.filter { $0.price <= max }
        }
        if !query.conditions.isEmpty {
            filtered = filtered.filter { query.conditions.contains($0.condition) }
        }

        let sorted = filtered.sorted {
            if $0.title.localizedCaseInsensitiveCompare($1.title) != .orderedSame {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.createdAt > $1.createdAt
        }
        return paginate(sorted, cursor: query.cursor)
    }

    // MARK: - Helpers

    private func paginate(_ listings: [Listing], cursor: String?) -> ListingPage {
        let startIndex: Int
        if let cursor, let idx = cursor.toInt() {
            startIndex = idx
        } else {
            startIndex = 0
        }
        let endIndex = min(startIndex + Constants.pageSize, listings.count)
        guard startIndex < endIndex else {
            return ListingPage(listings: [], nextCursor: nil)
        }
        let slice = Array(listings[startIndex..<endIndex])
        let nextCursor = endIndex < listings.count ? String(endIndex) : nil
        return ListingPage(listings: slice, nextCursor: nextCursor)
    }

    /// Automated content check (spec §9.2). Returns `.flagged` if prohibited keywords match.
    private func moderationCheck(title: String, description: String) -> ModerationStatus {
        let haystack = (title + " " + description).lowercased()
        for keyword in Constants.prohibitedKeywords where haystack.contains(keyword) {
            return .flagged
        }
        return .approved
    }
}

private extension String {
    func toInt() -> Int? { Int(self) }
}
