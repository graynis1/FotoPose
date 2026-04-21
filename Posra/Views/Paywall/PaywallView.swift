import SwiftUI
import StoreKit

struct PaywallView: View {
    let isRootPaywall: Bool

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var isPurchasing: Bool = false

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    headlineSection
                    featuresCard
                    planCards
                    ctaSection
                    footer
                    Color.clear.frame(height: 20)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Floating close + restore
            VStack {
                HStack {
                    Button {
                        Task { await subscriptionService.restore() }
                    } label: {
                        Text("Restore")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Button {
                        handleClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .glass(tint: Color.black.opacity(0.35), borderOpacity: 0.15, cornerRadius: 16)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 16)
                Spacer()
            }
        }
        .statusBarHidden(false)
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            RemoteImage(
                url: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=1000&q=85&auto=format&fit=crop",
                focalPoint: UnitPoint(x: 0.5, y: 0.3)
            )
            .frame(height: 440)
            .clipped()

            // top darken
            LinearGradient(colors: [Color.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

            // bottom fade
            LinearGradient(colors: [.clear, DS.Colors.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 180)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

            VStack(spacing: 14) {
                // Pro badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                    Text("FOTOPOSE PRO")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.4)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(DS.Gradients.accent, in: Capsule())
                .shadow(color: DS.Colors.pink.opacity(0.5), radius: 12, x: 0, y: 10)

                // Social proof avatars
                HStack(spacing: 10) {
                    ZStack {
                        ForEach(Array(Self.avatarURLs.enumerated()), id: \.offset) { i, url in
                            RemoteImage(url: url)
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(DS.Colors.background, lineWidth: 2))
                                .offset(x: CGFloat(i) * 16)
                        }
                    }
                    .frame(width: 22 + CGFloat(Self.avatarURLs.count - 1) * 16, height: 22)

                    Group {
                        Text("240,000+ ").foregroundStyle(.white).bold()
                        + Text("photographers").foregroundStyle(Color.white.opacity(0.7))
                    }
                    .font(.system(size: 12))
                }

                // Rating
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.Colors.gold)
                        }
                    }
                    Text("4.9 · App Store")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            .padding(.bottom, 40)
        }
        .frame(height: 440)
    }

    private var headlineSection: some View {
        VStack(spacing: 10) {
            Text("Shoot like\nyou mean it.")
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(.white)
                .lineSpacing(-2)

            Text("240+ editorial poses, live AR guidance, and coaching that adapts to your body. No ads. No cloud.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .tracking(-0.15)
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(maxWidth: 290)
                .lineSpacing(2)
        }
        .padding(.horizontal, 28)
        .padding(.top, -30)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "sparkles",
                       title: "Unlimited AI pose suggestions",
                       sub: "Live environment + body-aware recommendations, any lighting.")
            FeatureRow(icon: "bolt.fill",
                       title: "Full pose library · 240+ poses",
                       sub: "Editorial, couple, wedding, street & group modes.")
            FeatureRow(icon: "camera.fill",
                       title: "Live AR pose overlay",
                       sub: "Match target poses in real time with body tracking.")
            FeatureRow(icon: "lock.fill",
                       title: "100% on-device privacy",
                       sub: "Nothing leaves your phone. Not even anonymised.")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(
            tint: Color.white.opacity(0.06),
            borderOpacity: 0.10,
            cornerRadius: DS.Radius.card
        )
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private var planCards: some View {
        HStack(spacing: 10) {
            ForEach(SubscriptionPlan.allCases) { plan in
                PlanCard(
                    plan: plan,
                    product: subscriptionService.product(for: plan),
                    selected: selectedPlan == plan,
                    badge: plan == .yearly ? "BEST VALUE" : nil
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPlan = plan
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await handlePurchase() }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    }
                    Text(ctaTitle)
                }
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(isPurchasing)

            Text(ctaSubtitle)
                .font(.system(size: 11.5))
                .tracking(-0.1)
                .foregroundStyle(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Text("Terms")
            Text("·")
            Text("Privacy")
            Text("·")
            Button("Restore") {
                Task { await subscriptionService.restore() }
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 11))
        .tracking(0.1)
        .foregroundStyle(Color.white.opacity(0.4))
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Derived

    private var ctaTitle: String {
        if case .inTrial = subscriptionService.status { return "Continue".localized }
        if case .active = subscriptionService.status { return "Continue".localized }
        return "Start 1-Day Free Trial".localized
    }

    private var ctaSubtitle: String {
        guard let product = subscriptionService.product(for: selectedPlan) else {
            return String.localized("paywall.cta.subtitle.noTrial",
                                    selectedPlan.fallbackPrice,
                                    selectedPlan.unitLabel)
        }
        return String.localized("paywall.cta.subtitle.withTrial",
                                product.displayPrice,
                                product.unitLabel)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        if subscriptionService.status.hasAccess {
            finish()
            return
        }
        isPurchasing = true
        let success = await subscriptionService.purchase(selectedPlan)
        isPurchasing = false
        if success { finish() }
    }

    private func handleClose() {
        if subscriptionService.status.hasAccess {
            finish()
        } else if isRootPaywall {
            // From the root paywall, closing also sends users into the app,
            // but without access gating. Per spec, gated views will reopen paywall.
            finish()
        } else {
            appState.dismissPaywall()
        }
    }

    private func finish() {
        if isRootPaywall {
            appState.finishPaywall()
        } else {
            appState.dismissPaywall()
        }
    }

    private static let avatarURLs: [String] = [
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&q=80&auto=format&fit=crop",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80&auto=format&fit=crop",
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80&auto=format&fit=crop",
        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80&auto=format&fit=crop"
    ]
}

// MARK: - Subviews

private struct FeatureRow: View {
    let icon: String
    let title: String
    let sub: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DS.Gradients.accentSoft)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DS.Colors.pink.opacity(0.3), lineWidth: 0.5)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Gradients.accent)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 14.5, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(sub))
                    .font(.system(size: 12.5))
                    .tracking(-0.1)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let product: Product?
    let selected: Bool
    let badge: String?

    var priceText: String {
        product?.displayPrice ?? plan.fallbackPrice
    }

    var unitText: String {
        product?.unitLabel ?? plan.unitLabel
    }

    var subtitleText: String {
        if let product, let sub = product.subscription, sub.introductoryOffer != nil {
            return "1-day trial".localized
        }
        return plan.fallbackSubtitle
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(LocalizedStringKey(plan.displayName))
                        .font(.system(size: 12.5, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(Color.white.opacity(0.75))
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(selected ? AnyShapeStyle(DS.Gradients.accent) : AnyShapeStyle(Color.clear))
                        Circle()
                            .stroke(selected ? Color.clear : Color.white.opacity(0.25), lineWidth: 1.5)
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 18, height: 18)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(priceText)
                        .font(.system(size: 22, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey("/\(unitText)"))
                        .font(.system(size: 12))
                        .tracking(-0.1)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .padding(.top, 8)

                Text(LocalizedStringKey(subtitleText))
                    .font(.system(size: 11.5))
                    .tracking(-0.1)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14.5, style: .continuous)
                    .fill(DS.Colors.cardBackground)
            )
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AnyShapeStyle(DS.Gradients.accent) : AnyShapeStyle(Color.white.opacity(0.1)))
            )
            .shadow(color: selected ? DS.Colors.pink.opacity(0.35) : .clear, radius: 14, x: 0, y: 10)

            if let badge {
                Text(LocalizedStringKey(badge))
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(DS.Colors.pinkSoft, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: DS.Colors.pink.opacity(0.5), radius: 8, x: 0, y: 4)
                    .offset(x: -10, y: -10)
            }
        }
    }
}

#Preview {
    PaywallView(isRootPaywall: true)
        .environmentObject(AppState())
        .environmentObject(SubscriptionService())
}
