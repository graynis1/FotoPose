import SwiftUI

@main
struct PosraApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
