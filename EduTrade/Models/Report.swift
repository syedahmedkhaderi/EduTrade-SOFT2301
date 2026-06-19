import Foundation

enum ReportStatus: String, Codable, CaseIterable {
    case open
    case resolved
    case dismissed
}

struct Report: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var listingID: String
    var reporterID: String
    var reason: String
    var status: ReportStatus
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        listingID: String,
        reporterID: String,
        reason: String,
        status: ReportStatus = .open,
        createdAt: Date = .now
    ) {
        self.id = id
        self.listingID = listingID
        self.reporterID = reporterID
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
    }
}
