import Foundation
import SwiftUI

/// Root navigation state. Decides between welcome, verify, and main tab views.
enum AppRoot: Equatable {
    case unauthenticated
    case needsVerification(User)
    case authenticated(User)
}

/// Global app state injected via @Environment.
@MainActor
final class AppState: ObservableObject {

    @Published var root: AppRoot = .unauthenticated
    @Published var isLoading: Bool = true
    @Published var preferredLanguage: AppLanguage = .english

    let services = ServiceContainer.shared
    let toasts = ToastCenter.shared

    /// Static reference set on init so ViewModels can access shared services
    /// and session state without needing appState passed through every init().
    static var current: AppState!

    // Cached lookups for display (seller profiles on listing cards).
    @Published var userCache: [String: User] = [:]

    init() {
        Self.current = self
        loadPreferredLanguage()
    }

    /// Convenience: the currently signed-in user (if any).
    static func sessionUser() -> User? {
        guard let root = current?.root else { return nil }
        switch root {
        case .authenticated(let u): return u
        case .needsVerification(let u): return u
        case .unauthenticated: return nil
        }
    }

    func bootstrap() async {
        await services.store.bootstrap()
        if let user = await services.auth.currentUser() {
            await applyUser(user)
        }
        isLoading = false
    }

    func applyUser(_ user: User) {
        userCache[user.id] = user
        if !user.isEmailVerified {
            root = .needsVerification(user)
        } else {
            root = .authenticated(user)
        }
    }

    func signOut() async {
        try? await services.auth.signOut()
        root = .unauthenticated
        userCache.removeAll()
    }

    // MARK: - Language

    func loadPreferredLanguage() {
        if let raw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.preferredLanguage),
           let lang = AppLanguage(rawValue: raw) {
            preferredLanguage = lang
        }
    }

    func setLanguage(_ lang: AppLanguage) {
        preferredLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: Constants.UserDefaultsKeys.preferredLanguage)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic  = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic:  return "العربية"
        }
    }

    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }
}
