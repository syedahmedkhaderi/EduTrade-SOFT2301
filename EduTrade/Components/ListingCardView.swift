import SwiftUI

/// Compact listing card for grid / list displays (spec §12.5, §12.6).
struct ListingCardView: View {
    let listing: Listing
    var sellerRating: Double = 0
    var sellerTotalRatings: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListingImage(imageKey: listing.imageURLs.first, title: listing.title, cornerRadius: 0)
                .frame(height: 140)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    ConditionTagView(condition: listing.condition)
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    Image(systemName: "graduationcap")
                        .font(.system(size: 10))
                    Text(listing.courseCode)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Theme.mutedText)

                HStack {
                    Text(Formatters.currency(listing.price))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.accentColor)
                    Spacer()
                    if sellerTotalRatings > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", sellerRating))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            .padding(10)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
