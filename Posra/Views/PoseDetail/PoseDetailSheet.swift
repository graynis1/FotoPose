import SwiftUI

/// Editorial pose detail sheet — animated silhouette hero (breathing/pulse),
/// lighting match, pro tips, similar poses, heart toggles favorite via
/// `PoseHistoryService`, gradient CTA routes back to Camera.
struct PoseDetailSheet: View {
    let pose: GeneratedPose
    let detection: DetectionResult
    var similar: [GeneratedPose] = []
    var onUsePose: () -> Void
    var onDismiss: () -> Void

    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var appState: AppState
    @StateObject private var history = PoseHistoryService.shared
    @State private var breathe: Bool = false
    @State private var saved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSilhouette
                        .padding(.top, 4)
                    titleBlock
                        .padding(.top, 18)
                    lightingMatchCard
                        .padding(.top, 18)

                    sectionHeader("Pro tips")
                        .padding(.top, 20)
                    VStack(spacing: 14) {
                        ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                            TipRow(icon: tip.icon, title: tip.title, body: tip.body)
                        }
                    }
                    .padding(.top, 12)

                    if !similar.isEmpty {
                        sectionHeader("Similar poses")
                            .padding(.top, 22)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(similar) { p in
                                    SimilarSilhouetteCard(pose: p)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.top, 10)
                    }

                    ctaRow
                        .padding(.top, 22)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            saved = history.isFavorite(pose)
            history.noteView(pose)
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("POSE DETAILS")
                .font(DS.Font.mono(11, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.white.opacity(0.45))
            Spacer()
            iconButton(system: saved ? "bookmark.fill" : "bookmark") {
                toggleFavorite()
            }
            iconButton(system: "square.and.arrow.up") { }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Hero — animated silhouette

    private var heroSilhouette: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#14121D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    DS.Colors.violet.opacity(0.28),
                                    DS.Colors.pink.opacity(0.10),
                                    .clear
                                ],
                                center: .center, startRadius: 0, endRadius: 240
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 24)

            PoseSilhouette(
                keypoints: pose.bodyKeypoints,
                stroke: DS.Gradients.accent,
                lineWidth: 3.2,
                glow: DS.Colors.pink.opacity(0.55),
                jointDots: true
            )
            .scaleEffect(breathe ? 1.015 : 0.995)
            .opacity(breathe ? 1.0 : 0.92)
            .padding(36)
            .frame(maxWidth: .infinity)

            if pose.isPro {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles").font(.system(size: 10, weight: .bold))
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DS.Gradients.accent, in: Capsule())
                .shadow(color: DS.Colors.pink.opacity(0.4), radius: 14, x: 0, y: 6)
                .padding(12)
            }

            if pose.isFallback {
                Text("Curated template")
                    .font(DS.Font.mono(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Colors.pink)
                    Text("AI-generated")
                        .font(DS.Font.mono(10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08), in: Capsule())
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: 360)
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(pose.name))
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(.white)
            Text(LocalizedStringKey(subtitleLine))
                .font(.system(size: 13))
                .tracking(-0.15)
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.top, 3)
            if !pose.description.isEmpty {
                Text(LocalizedStringKey(pose.description))
                    .font(.system(size: 14))
                    .tracking(-0.2)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .padding(.top, 10)
                    .lineSpacing(3)
            }

            FlowLayout(spacing: 6, runSpacing: 6) {
                ForEach(chips, id: \.label) { chip in
                    DetailChip(label: chip.label, accent: chip.accent)
                }
            }
            .padding(.top, 10)
        }
    }

    private var subtitleLine: String {
        var parts: [String] = [pose.categoryDisplayName]
        switch pose.personCount {
        case 0, 1: parts.append("Solo".localized)
        case 2:    parts.append("Couple".localized)
        default:   parts.append("Group".localized)
        }
        parts.append(pose.difficultyLabel)
        return parts.joined(separator: " · ")
    }

    private var chips: [(label: String, accent: Bool)] {
        var out: [(String, Bool)] = []
        if let primary = pose.suitableLighting.first, primary != .any {
            out.append((LightAnalyzerService.label(for: primary).title, false))
        }
        if let scene = pose.suitableScene.first, scene != .any {
            out.append((scene.rawValue.capitalized.localized, false))
        }
        let matchLabel = String.localized("detail.matchFormat", Int((pose.matchScore * 100).rounded()))
        out.append((matchLabel, true))
        return out
    }

    // MARK: - Lighting match

    private var lightingMatchCard: some View {
        let matched = pose.suitableLighting.contains(detection.detectedLighting)
            && detection.detectedLighting != .any
        let title: LocalizedStringKey = matched ? "Your lighting is a match" : "Lighting tip"
        let confidence = max(72, min(98, Int(detection.poseMatchConfidence * 100) + 60))
        let detail: String = {
            if matched {
                return String.localized(
                    "detail.lightingDetected",
                    LightAnalyzerService.label(for: detection.detectedLighting).title,
                    confidence
                )
            }
            if let first = pose.suitableLighting.first, first != .any {
                return String.localized(
                    "detail.lightingWorksBest",
                    LightAnalyzerService.label(for: first).title.lowercased()
                )
            }
            return "Flexible — works in most lighting".localized
        }()

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(matched ? DS.Colors.green.opacity(0.15) : Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)
                Image(systemName: matched ? "checkmark" : "lightbulb")
                    .font(.system(size: matched ? 14 : 15, weight: .bold))
                    .foregroundStyle(matched ? DS.Colors.green : DS.Colors.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .tracking(-0.15)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .tracking(-0.1)
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(matched ? DS.Colors.green.opacity(0.08) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(matched ? DS.Colors.green.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - CTA

    private var ctaRow: some View {
        HStack(spacing: 10) {
            Button {
                toggleFavorite()
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                Image(systemName: saved ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(saved ? DS.Colors.pink : .white)
                    .frame(width: 54, height: 54)
            }
            .buttonStyle(.plain)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )

            Button {
                if pose.isPro && !subscriptionService.status.isPro {
                    appState.presentPaywall()
                } else {
                    onUsePose()
                    onDismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Use This Pose")
                        .font(.system(size: 15.5, weight: .bold))
                        .tracking(-0.2)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(DS.Gradients.accent, in: Capsule())
                .shadow(color: DS.Colors.pink.opacity(0.45), radius: 14, x: 0, y: 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func toggleFavorite() {
        history.toggleFavorite(pose)
        saved = history.isFavorite(pose)
    }

    private func sectionHeader(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .textCase(.uppercase)
            .font(DS.Font.mono(11, weight: .bold))
            .tracking(1.8)
            .foregroundStyle(Color.white.opacity(0.45))
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.75))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private struct Tip {
        let icon: String
        let title: String
        let body: String
    }

    private var tips: [Tip] {
        let icons = ["bolt.fill", "sparkles", "camera.fill", "person.fill"]
        return pose.tips.prefix(4).enumerated().map { idx, text in
            let pieces = text.split(separator: "—", maxSplits: 1, omittingEmptySubsequences: true)
            if pieces.count == 2 {
                return Tip(icon: icons[idx % icons.count],
                           title: String(pieces[0]).trimmingCharacters(in: .whitespaces),
                           body: String(pieces[1]).trimmingCharacters(in: .whitespaces))
            }
            return Tip(icon: icons[idx % icons.count],
                       title: String.localized("detail.tipFallback", idx + 1),
                       body: text)
        }
    }
}

// MARK: - Similar pose card (silhouette)

private struct SimilarSilhouetteCard: View {
    let pose: GeneratedPose

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "#14121D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.violet.opacity(0.15), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
            PoseSilhouette(keypoints: pose.bodyKeypoints,
                           stroke: DS.Gradients.accent,
                           lineWidth: 1.6,
                           glow: DS.Colors.pink.opacity(0.4))
                .padding(12)

            Text(LocalizedStringKey(pose.name))
                .font(.system(size: 10, weight: .bold))
                .tracking(-0.1)
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
        }
        .frame(width: 90, height: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Chips & tip row

private struct DetailChip: View {
    let label: String
    var accent: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .tracking(-0.1)
            .foregroundStyle(accent ? DS.Colors.pinkSoft : Color.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(accent ? DS.Colors.pink.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule().stroke(accent ? DS.Colors.pink.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

private struct TipRow: View {
    let icon: String
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(DS.Colors.pink.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Colors.pink)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(DS.Colors.pink.opacity(0.25), lineWidth: 0.5)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13.5, weight: .semibold))
                    .tracking(-0.15)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(body))
                    .font(.system(size: 12.5))
                    .tracking(-0.1)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - FlowLayout (iOS 16+)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var runSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .init(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
