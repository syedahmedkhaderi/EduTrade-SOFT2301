import Foundation

/// App-wide constants.
enum Constants {
    // University
    static let universityName = "UDST"
    static let universityEmailDomain = "udst.edu.qa"

    // Platform
    static let commissionRate = 0.10  // 10%
    static let appName = "EduTrade"
    static let appTagline = "Buy & sell used academic materials at UDST"

    // UI
    static let maxListingImages = 6
    static let minListingImages = 1
    static let pageSize = 20

    // Subjects offered at UDST (spec §4.4 filter set).
    static let subjects: [String] = [
        "Computer Science",
        "Engineering",
        "Business",
        "Health Sciences",
        "Applied Sciences",
        "Information Technology",
        "Industrial Trades",
        "Mechanical",
        "Electrical",
        "Mathematics",
        "English Language",
        "Other"
    ]

    // Prohibited keywords for the automated content check (spec §9.2).
    static let prohibitedKeywords: [String] = [
        "weapon", "gun", "ammunition", "drug", "narcotic", "cannabis",
        "alcohol", "tobacco", "vape", "stolen", "counterfeit",
        "prescription", "exam", "answer key", "cheat"
    ]

    // Keys for UserDefaults.
    enum UserDefaultsKeys {
        static let recentSearches = "recentSearches"
        static let preferredLanguage = "preferredLanguage"
        static let hasOnboarded = "hasOnboarded"
    }
}

/// Errors thrown by services.
enum AppError: LocalizedError, Equatable {
    case invalidEmail
    case invalidPassword
    case emailAlreadyInUse
    case accountSuspended
    case emailNotVerified
    case notFound
    case unauthorized
    case moderationRejected
    case listingRequiresPhoto
    case ratingAlreadyExists
    case alreadyPurchased
    case cannotBuyOwnListing
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid UDST email (@udst.edu.qa)."
        case .invalidPassword:
            return "Password must be at least 8 characters with one letter and one number."
        case .emailAlreadyInUse:
            return "This email is already registered. Try signing in instead."
        case .accountSuspended:
            return "This account has been suspended. Please contact support."
        case .emailNotVerified:
            return "Please verify your university email to continue."
        case .notFound:
            return "The item you're looking for could not be found."
        case .unauthorized:
            return "You don't have permission to do that."
        case .moderationRejected:
            return "This listing was flagged and is under review."
        case .listingRequiresPhoto:
            return "At least one photo is required to publish a listing."
        case .ratingAlreadyExists:
            return "You've already rated this transaction."
        case .alreadyPurchased:
            return "This item has already been sold."
        case .cannotBuyOwnListing:
            return "You can't buy your own listing."
        case .generic(let msg):
            return msg
        }
    }
}
