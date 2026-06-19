import SwiftUI

@main
struct EduTradeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.toasts)
                .task {
                    if CommandLine.arguments.contains("-resetMockData") {
                        UserDefaults.standard.removeObject(forKey: "auth.currentUserID")
                        await appState.services.store.resetAll()
                    }
                    await appState.bootstrap()
                }
                .environment(\.layoutDirection, appState.preferredLanguage.layoutDirection)
        }
    }
}
