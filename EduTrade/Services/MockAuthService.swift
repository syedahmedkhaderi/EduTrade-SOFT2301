import Foundation

/// Mock authentication service backed by MockStore.
/// In production, replace with Firebase Auth. The protocol surface stays identical.
final class MockAuthService: AuthServiceProtocol {

    private let store: MockStore
    private let sessionKey = "auth.currentUserID"

    init(store: MockStore) { self.store = store }

    func register(fullName: String, email: String, password: String) async throws -> User {
        let normalized = email.trimmed.lowercased()
        guard Validators.isValidUniversityEmail(normalized) else { throw AppError.invalidEmail }
        guard Validators.isValidPassword(password) else { throw AppError.invalidPassword }

        let existing = await store.findUser(email: normalized)
        guard existing == nil else { throw AppError.emailAlreadyInUse }

        let user = User(
            fullName: fullName.trimmed,
            universityEmail: normalized,
            isEmailVerified: false
        )
        await store.upsertUser(user)
        await store.setCredential(email: normalized, password: password)
        await store.addPendingVerification(user.id)
        await persistSession(userID: user.id)
        return user
    }

    func sendEmailVerification(for user: User) async throws {
        // Mock: mark as verified after a short delay (simulating user clicking the email link).
        // We don't auto-verify here; reloadVerificationStatus flips it.
        await store.addPendingVerification(user.id)
    }

    func reloadVerificationStatus(for user: User) async throws -> User {
        // Mock: verify "instantly" when polled (simulates clicking the email link).
        if await store.isPendingVerification(user.id) {
            var updated = user
            updated.isEmailVerified = true
            await store.upsertUser(updated)
            await store.removePendingVerification(user.id)
            return updated
        }
        // Already verified path
        return await store.getUser(id: user.id) ?? user
    }

    func login(email: String, password: String) async throws -> User {
        let normalized = email.trimmed.lowercased()
        guard let user = await store.checkCredential(email: normalized, password: password) else {
            throw AppError.generic("Invalid email or password.")
        }
        if user.isSuspended { throw AppError.accountSuspended }
        await persistSession(userID: user.id)
        return user
    }

    func sendPasswordReset(to email: String) async throws {
        // Mock: no-op (would send reset email via Firebase).
    }

    /// Async version — returns the current persisted session user.
    func currentUser() async -> User? {
        guard let id = UserDefaults.standard.string(forKey: sessionKey) else { return nil }
        return await store.getUser(id: id)
    }

    func signOut() async throws {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // MARK: - Helpers

    private func persistSession(userID: String) async {
        UserDefaults.standard.set(userID, forKey: sessionKey)
    }
}
