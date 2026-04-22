import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Route: Equatable {
        case onboarding
        case paywall
        case main
    }

    enum MainTab: Hashable {
        case camera, library, settings
    }

    @Published var route: Route
    @Published var selectedTab: MainTab = .camera
    @Published var isPaywallPresented: Bool = false

    private let onboardingKey = "posra.onboarding.completed.v1"

    nonisolated init() {
        let completed = UserDefaults.standard.bool(forKey: "posra.onboarding.completed.v1")
        self.route = completed ? .main : .onboarding
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        route = .paywall
    }

    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        route = .paywall
    }

    func finishPaywall() {
        route = .main
    }

    func presentPaywall() {
        isPaywallPresented = true
    }

    func dismissPaywall() {
        isPaywallPresented = false
    }
}
