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

/// Branded splash / launch screen.
struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.primary, Theme.accentColor],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 16) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                Text(Constants.appName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text(Constants.appTagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .ignoresSafeArea()
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
