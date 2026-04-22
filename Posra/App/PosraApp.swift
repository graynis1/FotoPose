import Combine
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
                .task {
                    await subscriptionService.bootstrap()
                    await scheduleNotifications()
                }
                .onReceive(subscriptionService.$status) { newValue in
                    if case .inTrial(let expires) = newValue {
                        Task { await NotificationService.shared.scheduleTrialEndingNotification(trialExpires: expires) }
                    }
                }
        }
    }

    @MainActor
    private func scheduleNotifications() async {
        let goldenHourEnabled = UserDefaults.standard.object(forKey: "posra.settings.goldenHourAlerts") as? Bool ?? true
        if goldenHourEnabled {
            await NotificationService.shared.scheduleGoldenHourAlerts()
        }
        await NotificationService.shared.scheduleWeeklyReminder()
    }

    private func configureAppearance() {
        // Tab bar transparency — we render our own custom tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
