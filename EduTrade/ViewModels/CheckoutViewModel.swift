import Foundation

/// Checkout + payment ViewModel (spec §4.6, §12.10, §12.11).
@MainActor
final class CheckoutViewModel: ObservableObject {

    @Published var preview: CheckoutPreview?
    @Published var transaction: Transaction?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var paymentSucceeded = false

    private let service: TransactionServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.service = appState.services.transactions
    }

    func load(listingID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            preview = try await service.previewCheckout(listingID: listingID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pay(listingID: String) async -> Bool {
        guard let user = AppState.sessionUser() else {
            errorMessage = "Please sign in."
            return false
        }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let tx = try await service.createPaymentIntent(listingID: listingID, buyerID: user.id)
            let completed = try await service.completeTransaction(tx)
            transaction = completed
            paymentSucceeded = true
            appState.toasts.success("Payment successful! Seller has been notified.")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
