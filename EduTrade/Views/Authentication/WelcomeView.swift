import SwiftUI

/// Entry screen for unauthenticated users (spec §12.1).
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.primary, Theme.accentColor.opacity(0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo
                    VStack(spacing: 16) {
                        Image("LaunchLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                        Text(Constants.appName)
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(.white)

                        Text(Constants.appTagline)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Feature highlights
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "graduationcap.fill",
                                   text: "Verified UDST students only")
                        featureRow(icon: "creditcard.fill",
                                   text: "Secure payments with 10% platform fee")
                        featureRow(icon: "star.fill",
                                   text: "Trusted ratings & reviews")
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            showRegister = true
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(.white)
                                .foregroundStyle(Theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        }
                        .accessibilityIdentifier("createAccountButton")

                        Button {
                            showLogin = true
                        } label: {
                            HStack {
                                Text("Already have an account?")
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("Sign In")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .accessibilityIdentifier("signInButton")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
            .navigationDestination(isPresented: $showLogin) { LoginView() }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
            Text(text)
                .foregroundStyle(.white.opacity(0.95))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
