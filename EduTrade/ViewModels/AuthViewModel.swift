import Foundation

/// Authentication ViewModel (spec §4.1).
@MainActor
final class AuthViewModel: ObservableObject {

    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var resendCooldown = 0

    // Live validation flags (used to show inline errors).
    var isEmailValid: Bool { Validators.isValidUniversityEmail(email) }
    var isPasswordValid: Bool { Validators.isValidPassword(password) }
    var doPasswordsMatch: Bool { password == confirmPassword && !password.isEmpty }
    var canSubmitRegister: Bool {
        !fullName.trimmed.isEmpty &&
        isEmailValid &&
        isPasswordValid &&
        doPasswordsMatch &&
        !isLoading
    }
    var canSubmitLogin: Bool {
        Validators.isValidEmail(email) && !password.isEmpty && !isLoading
    }

    private let appState: AppState
    private let auth: AuthServiceProtocol

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.auth = appState.services.auth
    }

    // MARK: - Register

    func register() async -> Bool {
        guard canSubmitRegister else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await auth.register(fullName: fullName, email: email, password: password)
            try? await auth.sendEmailVerification(for: user)
            appState.applyUser(user)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Login

    func login() async -> Bool {
        guard canSubmitLogin else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await auth.login(email: email, password: password)
            appState.applyUser(user)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Verification

    func sendEmailVerification(for user: User) async {
        try? await auth.sendEmailVerification(for: user)
        startResendCooldown()
    }

    func checkVerification(for user: User) async {
        if let updated = try? await auth.reloadVerificationStatus(for: user) {
            if updated.isEmailVerified {
                appState.applyUser(updated)
            }
        }
    }

    func startResendCooldown() {
        resendCooldown = 60
        Task {
            while resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                resendCooldown -= 1
            }
        }
    }

    // MARK: - Password reset

    func sendPasswordReset() async {
        try? await auth.sendPasswordReset(to: email)
    }

    // MARK: - Sign out

    func signOut() async {
        await appState.signOut()
        fullName = ""
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
}
