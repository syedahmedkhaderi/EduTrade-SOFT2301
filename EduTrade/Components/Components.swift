import SwiftUI

/// Centralized design tokens (spec §4.2 — Apple HIG, 4.5:1 contrast).
enum Theme {

    // Brand
    static let accent = Color("AccentColor") // resolved from Assets
    static let accentFallback = Color(red: 0.0, green: 0.45, blue: 0.38)   // teal-green

    static let primary    = Color(red: 0.05, green: 0.40, blue: 0.35)  // deep teal
    static let secondary  = Color(red: 0.98, green: 0.72, blue: 0.22)  // warm gold
    static let background = Color(.systemGroupedBackground)
    static let card       = Color(.secondarySystemGroupedBackground)
    static let danger     = Color.red
    static let success    = Color.green
    static let mutedText  = Color.secondary

    static let cornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 16
    static let spacing: CGFloat = 12

    static var accentColor: Color {
        UIColor(named: "AccentColor") != nil ? accent : accentFallback
    }
}

/// Reusable primary button (spec §11.2 Components).
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isEnabled ? Theme.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

/// Secondary / outline button.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(Theme.accentColor)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.accentColor, lineWidth: 1.5)
            )
        }
    }
}

/// Condition tag chip (spec §11.2 Components).
struct ConditionTagView: View {
    let condition: Condition

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: condition.symbolName)
                .font(.system(size: 9))
            Text(condition.displayName)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(conditionColor.opacity(0.15))
        .foregroundStyle(conditionColor)
        .clipShape(Capsule())
    }

    private var conditionColor: Color {
        switch condition {
        case .new:    return .green
        case .likeNew:return .blue
        case .good:   return Theme.accentColor
        case .fair:   return .orange
        case .poor:   return .red
        }
    }
}

/// Star rating display (spec §11.2 Components, §4.5).
struct StarRatingView: View {
    let rating: Double
    let totalRatings: Int
    var size: CGFloat = 14
    var interactive: Bool = false
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star))
                    .font(.system(size: size))
                    .foregroundStyle(.orange)
                    .onTapGesture {
                        if interactive, let onTap { onTap(star) }
                    }
            }
            if totalRatings > 0 {
                Text(String(format: "%.1f (%d)", rating, totalRatings))
                    .font(.system(size: size - 2, weight: .medium))
                    .foregroundStyle(Theme.mutedText)
            } else if !interactive {
                Text(NSLocalizedString("no_ratings", value: "No ratings", comment: ""))
                    .font(.system(size: size - 2))
                    .foregroundStyle(Theme.mutedText)
            }
        }
    }

    private func starImageName(for star: Int) -> String {
        let value = Double(star)
        if rating >= value { return "star.fill" }
        if rating >= value - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Full-screen loading overlay.
struct LoadingOverlay: View {
    var message: String = "Loading…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        }
    }
}

/// Inline error banner.
struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .lineLimit(3)
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(Theme.danger)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

/// Empty state view.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 48))
                .foregroundStyle(Theme.mutedText)
            Text(title).font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
