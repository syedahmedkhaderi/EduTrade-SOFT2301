import Foundation

/// Toast / in-app notification system (spec §4.6 — payment confirmations; spec §4.8 — error banners).
@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let kind: Kind
        enum Kind { case success, error, info }
    }

    @Published var current: Toast?

    func success(_ message: String) { show(message, kind: .success) }
    func error(_ message: String) { show(message, kind: .error) }
    func info(_ message: String) { show(message, kind: .info) }

    private func show(_ message: String, kind: Toast.Kind) {
        let toast = Toast(message: message, kind: kind)
        current = toast
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.current?.id == toast.id { self.current = nil }
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
    }
}
