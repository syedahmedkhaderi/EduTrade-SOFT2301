import Foundation

// MARK: - Enums

enum Condition: String, Codable, CaseIterable, Identifiable {
    case new
    case likeNew
    case good
    case fair
    case poor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new:    return NSLocalizedString("condition_new", value: "New", comment: "")
        case .likeNew:return NSLocalizedString("condition_like_new", value: "Like New", comment: "")
        case .good:   return NSLocalizedString("condition_good", value: "Good", comment: "")
        case .fair:   return NSLocalizedString("condition_fair", value: "Fair", comment: "")
        case .poor:   return NSLocalizedString("condition_poor", value: "Poor", comment: "")
        }
    }

    /// SF Symbol used for compact condition chips.
    var symbolName: String {
        switch self {
        case .new:    return "sparkles"
        case .likeNew:return "wand.and.stars"
        case .good:   return "hand.thumbsup"
        case .fair:   return "minus.circle"
        case .poor:   return "exclamationmark.triangle"
        }
    }

    /// Sort weight: new is best.
    var sortOrder: Int {
        switch self {
        case .new:    return 0
        case .likeNew:return 1
        case .good:   return 2
        case .fair:   return 3
        case .poor:   return 4
        }
    }
}

enum ListingStatus: String, Codable, CaseIterable {
    case draft
    case active
    case sold
    case removed
}

enum ModerationStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case flagged
    case rejected

    var isPubliclyVisible: Bool { self == .approved }
}

// MARK: - Listing

struct Listing: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var sellerID: String
    var title: String
    var description: String
    var courseCode: String
    var subject: String
    var price: Double
    var condition: Condition
    var imageURLs: [String]
    var status: ListingStatus
    var moderationStatus: ModerationStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        sellerID: String,
        title: String,
        description: String,
        courseCode: String,
        subject: String,
        price: Double,
        condition: Condition,
        imageURLs: [String],
        status: ListingStatus = .active,
        moderationStatus: ModerationStatus = .pending,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sellerID = sellerID
        self.title = title
        self.description = description
        self.courseCode = courseCode
        self.subject = subject
        self.price = price
        self.condition = condition
        self.imageURLs = imageURLs
        self.status = status
        self.moderationStatus = moderationStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
