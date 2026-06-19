import Foundation

/// Authentication service (spec §4.1, §9.1).
protocol AuthServiceProtocol {
    /// Registers a new student. Email must end with @udst.edu.qa.
    func register(fullName: String, email: String, password: String) async throws -> User
    /// Sends a verification email (mock auto-verifies after a short delay).
    func sendEmailVerification(for user: User) async throws
    /// Polls for email verification status.
    func reloadVerificationStatus(for user: User) async throws -> User
    /// Logs in with email + password.
    func login(email: String, password: String) async throws -> User
    /// Sends a password reset email.
    func sendPasswordReset(to email: String) async throws
    /// Current persisted session user, if any.
    func currentUser() async -> User?
    /// Signs out.
    func signOut() async throws
}
