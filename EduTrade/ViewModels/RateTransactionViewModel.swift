import Foundation

/// Rating submission ViewModel (spec §4.5, §12.15).
@MainActor
final class RateTransactionViewModel: ObservableObject {

    @Published var stars: Int = 5
    @Published var comment = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var didSubmit = false

    private let service: RatingServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.service = appState.services.ratings
    }

    func submit(transaction: Transaction) async -> Bool {
        guard let rater = AppState.sessionUser() else {
            errorMessage = "Please sign in."
            return false
        }
        let rateeID = (rater.id == transaction.buyerID) ? transaction.sellerID : transaction.buyerID

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await service.submitRating(
                transactionID: transaction.id,
                raterID: rater.id,
                rateeID: rateeID,
                stars: stars,
                comment: comment.trimmed.isEmpty ? nil : comment.trimmed
            )
            didSubmit = true
            appState.toasts.success("Rating submitted. Thank you!")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func hasAlreadyRated(transaction: Transaction) async -> Bool {
        guard let rater = AppState.sessionUser() else { return false }
        let existing = try? await service.fetchRating(for: transaction.id, byRater: rater.id)
        return existing != nil
    }
}
