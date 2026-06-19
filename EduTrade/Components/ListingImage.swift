import SwiftUI

/// Renders a listing photo. For mock image keys, generates a branded gradient placeholder
/// with the listing's initials. For real URLs, uses AsyncImage.
struct ListingImage: View {
    let imageKey: String?
    let title: String
    var cornerRadius: CGFloat = Theme.cardCornerRadius

    var body: some View {
        Group {
            if let key = imageKey, key.hasPrefix("http"), let url = URL(string: key) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:  placeholder
                    case .success(let img): img.resizable()
                    case .failure: placeholder
                    @unknown default: placeholder
                    }
                }
            } else {
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

    /// Pick a representative SF Symbol based on the mock key.
    private func iconName(for key: String?) -> String {
        guard let key else { return "book" }
        if key.contains("textbook") { return "textbook" }
        if key.contains("labkit")   { return "wrench.and.screwdriver" }
        if key.contains("notes")    { return "note.text" }
        return "book"
    }

    /// Stable gradient based on the title hash so each listing has distinct but consistent colors.
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
