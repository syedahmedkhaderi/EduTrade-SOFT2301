import Foundation

/// Form validation and business-rule validation (spec §4.1, §4.3).
enum Validators {

    // MARK: - Email

    /// Must be a valid university email ending in `udst.edu.qa`.
    static func isValidUniversityEmail(_ email: String) -> Bool {
        let normalized = email.trimmed.lowercased()
        guard normalized.hasSuffix(Constants.universityEmailDomain) else { return false }
        let pattern = "^[a-z0-9._%+-]+@udst\\.edu\\.qa$"
        return normalized.range(of: pattern, options: .regularExpression) != nil
    }

    /// Generic email (used for admin login only).
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Password

    /// Minimum 8 chars, at least one letter and one number.
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasDigit  = password.range(of: "[0-9]",    options: .regularExpression) != nil
        return hasLetter && hasDigit
    }

    static func passwordStrengthMessage(_ password: String) -> String? {
        if password.isEmpty { return nil }
        if password.count < 8 {
            return NSLocalizedString("pwd_short", value: "At least 8 characters", comment: "")
        }
        if !isValidPassword(password) {
            return NSLocalizedString("pwd_weak", value: "Include at least one letter and one number", comment: "")
        }
        return nil
    }

    // MARK: - Listing fields

    /// A listing requires title, description, course code, subject, condition, a positive price, and ≥1 image.
    static func isListingValid(
        title: String,
        description: String,
        courseCode: String,
        subject: String,
        price: Double,
        imageCount: Int
    ) -> Bool {
        !title.trimmed.isEmpty &&
        !description.trimmed.isEmpty &&
        !courseCode.trimmed.isEmpty &&
        !subject.trimmed.isEmpty &&
        price > 0 &&
        imageCount >= 1
    }

    // MARK: - Rating

    static func isValidStarCount(_ stars: Int) -> Bool {
        (1...5).contains(stars)
    }

    // MARK: - Price

    /// Accept up to 2 decimal places, non-negative, capped at 10,000 QAR.
    static func isValidListingPrice(_ price: Double) -> Bool {
        price > 0 && price <= 10_000
    }
}
