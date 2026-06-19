import SwiftUI

/// Renders a listing photo.
/// For bundled asset keys (mock seed data), loads the realistic textbook cover image.
/// For real URLs, uses AsyncImage. Falls back to a branded placeholder if neither is found.
struct ListingImage: View {
    let imageKey: String?
    let title: String
    var cornerRadius: CGFloat = Theme.cardCornerRadius

    var body: some View {
        Group {
            if let key = imageKey, key.hasPrefix("http"), let url = URL(string: key) {
                // Real remote URL (production)
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:  placeholder
                    case .success(let img): img.resizable()
                    case .failure: placeholder
                    @unknown default: placeholder
                    }
                }
            } else if let key = imageKey, let uiImage = UIImage(named: key) {
                // Bundled asset (mock seed data — realistic textbook covers)
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                // Fallback branded placeholder
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: iconName(for: imageKey))
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.95))
                Text(initials)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var initials: String {
        let words = title.split(separator: " ").prefix(2)
        return words.compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }

    private func iconName(for key: String?) -> String {
        guard let key else { return "book" }
        if key.contains("textbook") { return "textbook" }
        if key.contains("labkit")   { return "wrench.and.screwdriver" }
        if key.contains("notes")    { return "note.text" }
        return "book"
    }

    private var gradientColors: [Color] {
        let palettes: [[Color]] = [
            [Color.teal, Color.blue],
            [Color.indigo, Color.purple],
            [Color.orange, Color.red],
            [Color.green, Color.teal],
            [Color.pink, Color.purple],
            [Color.blue, Color.cyan],
            [Color.yellow, Color.orange]
        ]
        let hash = abs(title.hashValue)
        return palettes[hash % palettes.count]
    }
}
