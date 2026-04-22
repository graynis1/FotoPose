import SwiftUI

@main
struct PosraApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .preferredColorScheme(.dark)
                .onAppear {
                    configureAppearance()
                }
        }
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
