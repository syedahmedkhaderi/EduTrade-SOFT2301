import SwiftUI

/// Email verification screen (spec §4.1, §12.3).
struct VerifyEmailView: View {
    @EnvironmentObject var appState: AppState
    let user: User

    @State private var pollTimer: Timer?
    @State private var isChecking = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accentColor)

                Text("Check your email")
                    .font(.title2.bold())

                Text("We sent a verification link to")
                    .foregroundStyle(Theme.mutedText)
                Text(user.universityEmail)
                    .fontWeight(.semibold)

                Text("Tap the link in your university inbox to verify your account. This screen will advance automatically.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await checkNow() }
                } label: {
                    HStack {
                        if isChecking { ProgressView().tint(.white) }
                        Text("I've verified — check now")
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    appState.root = .unauthenticated
                } label: {
                    Text("Use a different account")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            // Auto-poll every 3 seconds (mock auto-verifies on first poll).
            pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                Task { await checkNow() }
            }
        }
        .onDisappear { pollTimer?.invalidate() }
    }

    @MainActor
    private func checkNow() async {
        guard !isChecking else { return }
        isChecking = true
        do {
            _ = try await appState.services.auth.reloadVerificationStatus(for: user)
        } catch {
            // ignore poll errors
        }
        if case .authenticated = appState.root {
            pollTimer?.invalidate()
        }
        isChecking = false
    }
}
