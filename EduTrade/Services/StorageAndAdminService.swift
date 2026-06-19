import Foundation
import UIKit

/// Image storage service (spec §6.2, Firebase Storage). Mock stores names in-memory.
protocol StorageServiceProtocol {
    /// Uploads an image and returns its (mock) URL.
    func uploadImage(_ image: UIImage, folder: String) async throws -> String
    /// Resolves a stored image URL to a displayable URL (mock returns the same / placeholder).
    func resolveURL(_ key: String) -> URL?
}

/// Admin moderation service (spec §4.9, §10.5, §10.6).
protocol AdminServiceProtocol {
    func fetchReports() async throws -> [Report]
    func fetchFlaggedListings() async throws -> [Listing]
    func fetchAllUsers() async throws -> [User]
    func resolveReport(reportID: String, action: AdminResolution) async throws
    func resolveListing(listingID: String, status: ModerationStatus) async throws
    func setUserSuspended(userID: String, suspended: Bool) async throws
    func reportListing(listingID: String, reporterID: String, reason: String) async throws
}

enum AdminResolution: String {
    case approveListing, removeListing, dismissReport
}
