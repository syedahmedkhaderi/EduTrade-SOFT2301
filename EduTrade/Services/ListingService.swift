import Foundation

/// Listing + search service (spec §4.3, §4.4, §10.1, §10.2).
protocol ListingServiceProtocol {
    func fetchActiveListings(cursor: String?) async throws -> ListingPage
    func fetchListing(id: String) async throws -> Listing?
    func fetchListings(bySeller sellerID: String, includeSold: Bool) async throws -> [Listing]
    func createListing(_ listing: Listing) async throws -> Listing
    func updateListing(_ listing: Listing) async throws -> Listing
    func deleteListing(id: String) async throws
    func markAsSold(id: String) async throws
    func searchListings(query: SearchQuery) async throws -> ListingPage
}
