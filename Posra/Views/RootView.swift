import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            switch appState.route {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .paywall:
                PaywallView(isRootPaywall: true)
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.route)
        .fullScreenCover(isPresented: $appState.isPaywallPresented) {
            PaywallView(isRootPaywall: false)
        }
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

    @MainActor
    private func scheduleNotifications() async {
        let goldenHourEnabled = UserDefaults.standard.object(forKey: "posra.settings.goldenHourAlerts") as? Bool ?? true
        if goldenHourEnabled {
            await NotificationService.shared.scheduleGoldenHourAlerts()
        }
        await NotificationService.shared.scheduleWeeklyReminder()
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService())
}
