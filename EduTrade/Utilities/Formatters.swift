import Foundation
import SwiftUI

/// Formatting helpers for currency, dates, ratings.
enum Formatters {

    /// Currency formatter for Qatari Riyal.
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "QAR"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.locale = Locale.current
        return f
    }()

    /// Formats a double as QAR currency, e.g. "QAR 150.00".
    static func currency(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "QAR \(value.roundedTo2())"
    }

    /// Short currency without ISO code, e.g. "150.00 QAR".
    static func currencyShort(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return "\(nf.string(from: NSNumber(value: value)) ?? "\(value.roundedTo2())") QAR"
    }

    /// Compact decimal price (no currency) e.g. "150".
    static func price(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    // MARK: - Date

    static let dateRelative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    static func relativeDate(_ date: Date) -> String {
        dateRelative.localizedString(for: date, relativeTo: .now)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // MARK: - Rating

    static func rating(_ average: Double, _ count: Int) -> String {
        if count == 0 {
            return NSLocalizedString("no_ratings", value: "No ratings yet", comment: "")
        }
        let star = String(format: "%.1f", average)
        return "\(star) ★ (\(count))"
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
