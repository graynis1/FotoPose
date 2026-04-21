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
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService())
}
