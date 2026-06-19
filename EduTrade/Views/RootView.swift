import SwiftUI

/// Root view that switches between auth, verification, and main app (spec §13).
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var toasts: ToastCenter

    var body: some View {
        ZStack {
            switch appState.root {
            case .unauthenticated:
                WelcomeView()
            case .needsVerification(let user):
                VerifyEmailView(user: user)
            case .authenticated(let user):
                MainTabView(user: user)
            }

            // Splash
            if appState.isLoading {
                SplashView()
            }

            // Toasts
            if let toast = toasts.current {
                VStack {
                    Spacer()
                    ToastView(toast: toast)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: toasts.current)
            }
        }
    }
}

/// Branded animated splash / launch screen.
/// Shows the EduTrade logo centered with the app name and tagline for ~2.5s.
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.primary, Theme.accentColor],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 20) {
                Spacer()

                // Logo with spring entrance
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 15, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name
                Text(Constants.appName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)

                // Tagline
                Text(Constants.appTagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .opacity(taglineOpacity)

                Spacer()

                // Loading indicator
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("UDST Student Marketplace")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Staggered entrance animation
            withAnimation(.spring(duration: 0.8, bounce: 0.4).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                textOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.9)) {
                taglineOpacity = 1.0
            }
        }
        .transition(.opacity)
    }
}

/// In-app toast view.
struct ToastView: View {
    let toast: ToastCenter.Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(.white)
            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(color)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }

    private var iconName: String {
        switch toast.kind {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private var color: Color {
        switch toast.kind {
        case .success: return Theme.success
        case .error:   return Theme.danger
        case .info:    return Theme.accentColor
        }
    }
}
