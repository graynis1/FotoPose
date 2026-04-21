import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var appState: AppState

    @AppStorage("posra.settings.gridOverlay") private var gridOverlay: Bool = true
    @AppStorage("posra.settings.overlayOpacity") private var overlayOpacity: Double = 0.55
    @AppStorage("posra.settings.timerDefault") private var timerDefault: Int = 3
    @AppStorage("posra.settings.haptics") private var haptics: Bool = true
    @AppStorage("posra.settings.showEnvTags") private var showEnvTags: Bool = true
    @AppStorage("posra.settings.detectionSensitivity") private var detectionSensitivity: Double = 0.78
    @AppStorage("posra.settings.goldenHourAlerts") private var goldenHourAlerts: Bool = true

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [DS.Colors.violet.opacity(0.22), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 12)
                .offset(x: 110, y: -180)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    title
                        .padding(.top, 62)
                        .padding(.horizontal, 20)

                    subscriptionHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 22)

                    if subscriptionService.status.isPro {
                        ProCard()
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    } else {
                        FreeCard {
                            appState.presentPaywall()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }

                    cameraSection
                    aiSection
                    notificationsSection
                    aboutSection

                    Text("Made with care · © 2026 FotoPose")
                        .font(.system(size: 12))
                        .tracking(-0.1)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 26)

                    Color.clear.frame(height: 120) // reserve for tab bar
                }
            }
        }
    }

    private var title: some View {
        Text("Settings")
            .font(.system(size: 34, weight: .bold))
            .tracking(-1)
            .foregroundStyle(.white)
    }

    private var subscriptionHeader: some View {
        HStack {
            Text("SUBSCRIPTION")
                .font(.system(size: 13))
                .tracking(-0.1)
                .foregroundStyle(Color.white.opacity(0.6))
            Spacer()
        }
    }

    // MARK: - Sections

    private var cameraSection: some View {
        SettingsSection(header: "Camera") {
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.violet, system: "square.grid.3x3.fill"),
                label: "Grid Overlay"
            ) {
                IOSToggle(isOn: $gridOverlay)
            }
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.pink, system: "sparkles"),
                label: "Pose Overlay Opacity",
                sublabel: String.localized("settings.percent", Int(overlayOpacity * 100))
            ) {
                Slider(value: $overlayOpacity, in: 0.2...1.0)
                    .tint(DS.Colors.pink)
                    .frame(width: 140)
            }
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.gold, system: "timer"),
                label: "Timer Default"
            ) {
                SegmentedPicker(options: [3, 5, 10], selection: $timerDefault) {
                    String.localized("settings.seconds", $0)
                }
            }
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.green, system: "iphone.radiowaves.left.and.right"),
                label: "Haptic Feedback",
                isLast: true
            ) {
                IOSToggle(isOn: $haptics)
            }
        }
    }

    private var aiSection: some View {
        SettingsSection(
            header: "AI Detection",
            footer: "All AI processing happens on your device. No photos are ever uploaded."
        ) {
            SettingsRow(
                icon: SettingsIcon(tint: Color(hex: "#7C3AED"), system: "sparkles"),
                label: "Show Environment Tags"
            ) {
                IOSToggle(isOn: $showEnvTags)
            }
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.pink, system: "person.crop.circle"),
                label: "Person Detection",
                sublabel: sensitivityLabel,
                isLast: true
            ) {
                Slider(value: $detectionSensitivity, in: 0.3...1.0)
                    .tint(DS.Colors.pink)
                    .frame(width: 140)
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection(header: "Notifications") {
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.gold, system: "sun.and.horizon.fill"),
                label: "Golden Hour Alerts",
                sublabel: "Notify me when light is perfect",
                isLast: true
            ) {
                IOSToggle(isOn: $goldenHourAlerts)
                    .onChange(of: goldenHourAlerts) { enabled in
                        Task {
                            if enabled {
                                await NotificationService.shared.requestAuthorizationIfNeeded()
                                await NotificationService.shared.scheduleGoldenHourAlerts()
                            } else {
                                NotificationService.shared.cancelGoldenHourAlerts()
                            }
                        }
                    }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(header: "About") {
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.gold, system: "star.fill"),
                label: "Rate FotoPose",
                chevron: true
            ) { EmptyView() }
                .onTapGesture { requestReview() }
            SettingsRow(
                icon: SettingsIcon(tint: DS.Colors.green, system: "square.and.arrow.up.on.square.fill"),
                label: "Share with Friends",
                chevron: true
            ) { EmptyView() }
            SettingsRow(
                icon: SettingsIcon(tint: Color(hex: "#60A5FA"), system: "lock.shield.fill"),
                label: "Privacy Policy",
                chevron: true
            ) { EmptyView() }
            SettingsRow(
                icon: SettingsIcon(tint: Color(hex: "#9CA3AF"), system: "doc.text.fill"),
                label: "Terms of Service",
                chevron: true
            ) { EmptyView() }
            SettingsRow(
                icon: SettingsIcon(tint: Color.white.opacity(0.12), system: "info"),
                label: "App Version",
                isLast: true
            ) {
                Text(versionString)
                    .font(DS.Font.mono(13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    // MARK: - Helpers

    private var sensitivityLabel: String {
        let pct = Int(detectionSensitivity * 100)
        switch detectionSensitivity {
        case ..<0.5: return String.localized("settings.sensitivity.low", pct)
        case 0.5..<0.8: return String.localized("settings.sensitivity.medium", pct)
        default: return String.localized("settings.sensitivity.high", pct)
        }
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Section containers

private struct SettingsSection<Content: View>: View {
    let header: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(header))
                .textCase(.uppercase)
                .font(.system(size: 13))
                .tracking(-0.1)
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "#1C1C1E").opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)

            if let footer {
                Text(LocalizedStringKey(footer))
                    .font(.system(size: 13))
                    .tracking(-0.1)
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineSpacing(1.5)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }
        }
    }
}

private struct SettingsIcon: View {
    let tint: Color
    let system: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint)
                .frame(width: 29, height: 29)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            Image(systemName: system)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct SettingsRow<Accessory: View>: View {
    let icon: SettingsIcon
    let label: String
    var sublabel: String? = nil
    var chevron: Bool = false
    var isLast: Bool = false
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 15))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                if let sublabel {
                    Text(LocalizedStringKey(sublabel))
                        .font(.system(size: 11.5))
                        .tracking(-0.1)
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
            Spacer(minLength: 8)
            accessory
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 55)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct IOSToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(GradientToggleStyle())
    }
}

private struct GradientToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { configuration.isOn.toggle() }
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn
                          ? AnyShapeStyle(DS.Gradients.accent)
                          : AnyShapeStyle(Color(hex: "#787880").opacity(0.32)))
                    .frame(width: 51, height: 31)
                Circle()
                    .fill(.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1.5)
                    .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SegmentedPicker<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isActive = option == selection
                Text(label(option))
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Group {
                            if isActive {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(DS.Gradients.accent)
                                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) { selection = option }
                    }
            }
        }
        .padding(2)
        .background(Color(hex: "#767680").opacity(0.24), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

// MARK: - Subscription cards

private struct FreeCard: View {
    let onUpgrade: () -> Void
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Gradients.accent)
                .padding(1.5)
                .shadow(color: DS.Colors.violet.opacity(0.28), radius: 22, y: 14)

            RoundedRectangle(cornerRadius: 14.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DS.Colors.violet.opacity(0.16), Color(hex: "#0F0F14").opacity(0.98)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .padding(1.5)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FREE PLAN")
                            .font(DS.Font.mono(10, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text("You're on Free")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(-0.3)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("Daily poses")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.65))
                        Spacer()
                        Text(String.localized("settings.dailyUsage", 3, 3))
                            .font(DS.Font.mono(11.5, weight: .semibold))
                            .foregroundStyle(DS.Colors.pinkSoft)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(DS.Gradients.accent)
                                .frame(width: proxy.size.width)
                        }
                    }
                    .frame(height: 5)
                }

                Button(action: onUpgrade) {
                    HStack(spacing: 8) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(-0.1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(DS.Gradients.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: DS.Colors.pink.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(minHeight: 170)
    }
}

private struct ProCard: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Gradients.accent)
                .shadow(color: DS.Colors.pink.opacity(0.35), radius: 22, y: 14)

            Circle()
                .fill(
                    RadialGradient(colors: [Color.white.opacity(0.22), .clear],
                                   center: .center, startRadius: 0, endRadius: 90)
                )
                .frame(width: 180, height: 180)
                .offset(x: 180, y: -40)
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                        Text(LocalizedStringKey(headerText))
                            .textCase(.uppercase)
                            .font(DS.Font.mono(10, weight: .bold))
                            .tracking(1.8)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text("FotoPose Pro is active")
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                Text(renewalLine)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.white.opacity(0.85))

                Divider()
                    .overlay(Color.white.opacity(0.25))
                    .padding(.vertical, 6)

                HStack {
                    Text("Manage Subscription")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .contentShape(Rectangle())
                .onTapGesture { openManageSubscription() }
            }
            .padding(16)
        }
        .frame(minHeight: 150)
    }

    private var headerText: String {
        switch subscriptionService.status {
        case .inTrial: return "Pro · Free Trial".localized
        case .active(_, let pid):
            if pid.hasSuffix("yearly")  { return "Pro · Yearly".localized }
            if pid.hasSuffix("monthly") { return "Pro · Monthly".localized }
            if pid.hasSuffix("weekly")  { return "Pro · Weekly".localized }
            return "Pro".localized
        default: return "Pro".localized
        }
    }

    private var renewalLine: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        switch subscriptionService.status {
        case .inTrial(let date):
            return String.localized("settings.trialEnds", formatter.string(from: date))
        case .active(let date, _):
            return String.localized("settings.renews", formatter.string(from: date))
        default:
            return "Active".localized
        }
    }

    private func openManageSubscription() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}
