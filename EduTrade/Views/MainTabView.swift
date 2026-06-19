import SwiftUI

/// Primary tab navigation (spec §13).
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    let user: User

    var body: some View {
        TabView(selection: $appState.tabSelection) {
            HomeFeedView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            CreateListingView()
                .tabItem {
                    Label("Sell", systemImage: "plus.circle.fill")
                }
                .tag(2)

            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)

            if user.isAdmin {
                AdminDashboardView()
                    .tabItem {
                        Label("Admin", systemImage: "shield.lefthalf.filled")
                    }
                    .tag(4)
            }
        }
        .tint(Theme.accentColor)
    }
}

// Extend AppState to hold the tab selection.
extension AppState {
    var tabSelection: Int {
        get { UserDefaults.standard.integer(forKey: "tabSelection") }
        set { UserDefaults.standard.set(newValue, forKey: "tabSelection") }
    }
}
