import SwiftUI

/// Horizontal strip of AI-generated poses. Every card is a mini silhouette
/// skeleton drawn from the pose's keypoints — no photos, no static thumbnails.
struct PoseCardCarousel: View {
    let poses: [GeneratedPose]
    let selectedID: String?
    /// Shows shimmer placeholders when true.
    var isLoading: Bool = false
    /// Non-nil when we're on fallback mode — rendered as a subtle banner above the row.
    var fallbackBanner: String? = nil
    let onSelect: (GeneratedPose) -> Void
    var onDetail: (GeneratedPose) -> Void = { _ in }
    var onRefresh: () -> Void = {}
    var onSeeAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            if let fallbackBanner {
                FallbackBanner(text: fallbackBanner)
                    .padding(.horizontal, 16)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if isLoading && poses.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCardShimmer()
                        }
                    } else {
                        ForEach(poses) { pose in
                            PoseCard(
                                pose: pose,
                                isSelected: pose.id == selectedID
                            )
                            .onTapGesture { onSelect(pose) }
                            .onLongPressGesture(minimumDuration: 0.35) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                onDetail(pose)
                            }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: poses.map(\.id))
            }
        }
    }

    private var headerRow: some View {
        HStack {
            HStack(spacing: 6) {
                Text("SUGGESTED POSES")
                    .font(DS.Font.mono(11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Color.white.opacity(0.55))
                if isLoading {
                    PulsingSparkle()
                }
            }
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onRefresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 28, height: 24)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
            Button(action: onSeeAll) {
                Text("See all")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Colors.pink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - PoseCard

struct PoseCard: View {
    let pose: GeneratedPose
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Silhouette skeleton on gradient background
            SilhouetteCardBackground()
            PoseSilhouette(keypoints: pose.bodyKeypoints,
                           stroke: DS.Gradients.accent,
                           lineWidth: 1.8,
                           glow: DS.Colors.pink.opacity(0.55))
                .padding(10)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
            .allowsHitTesting(false)

            // Title
            Text(LocalizedStringKey(pose.name))
                .font(.system(size: 11, weight: .bold))
                .tracking(-0.1)
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.horizontal, 7)
                .padding(.bottom, 6)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)

            // PRO badge
            if pose.isPro {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8, weight: .bold))
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.6)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(DS.Gradients.accent, in: Capsule())
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Selected checkmark
            if isSelected {
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Colors.pink)
                    )
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            // Match score dots, bottom-left inside the gradient
            if !pose.isPro {
                MatchDots(score: pose.matchScore)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 88, height: 118)
        .padding(isSelected ? 2 : 0)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(DS.Gradients.accent) : AnyShapeStyle(Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                .stroke(isSelected ? Color.clear : Color.white.opacity(0.15), lineWidth: 0.5)
                .padding(isSelected ? 2 : 0)
        )
        .shadow(color: isSelected ? DS.Colors.pink.opacity(0.45) : .clear, radius: 12, x: 0, y: 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Skeleton rendering

/// Draws a line-art silhouette from normalized keypoints within its own bounds.
/// Reusable across cards, hero, and detail views.
struct PoseSilhouette: View {
    let keypoints: PoseKeypoints
    var stroke: any ShapeStyle = DS.Gradients.accent
    var lineWidth: CGFloat = 2
    var glow: Color = DS.Colors.pink.opacity(0.5)
    var jointDots: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rect = CGRect(origin: .zero, size: size)
            let pts = map(into: rect)
            ZStack {
                // Bones
                Path { path in
                    for (a, b) in PoseKeypoints.bones {
                        let p1 = pts[a] ?? .zero
                        let p2 = pts[b] ?? .zero
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                }
                .stroke(
                    AnyShapeStyle(stroke),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: glow, radius: lineWidth * 2)

                // Head circle
                if let head = pts[PoseKeypoints.Key.head] {
                    let radius = size.width * 0.08
                    Circle()
                        .stroke(AnyShapeStyle(stroke), lineWidth: lineWidth)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(head)
                        .shadow(color: glow, radius: lineWidth * 2)
                }

                // Joint dots
                if jointDots {
                    ForEach(PoseKeypoints.Key.allCases, id: \.self) { key in
                        if let p = pts[key] {
                            Circle()
                                .fill(.white)
                                .frame(width: max(2, lineWidth * 1.3),
                                       height: max(2, lineWidth * 1.3))
                                .position(p)
                        }
                    }
                }
            }
        }
    }

    private func map(into rect: CGRect) -> [PoseKeypoints.Key: CGPoint] {
        var map: [PoseKeypoints.Key: CGPoint] = [:]
        for key in PoseKeypoints.Key.allCases {
            let n = keypoints.point(key)
            map[key] = CGPoint(
                x: rect.origin.x + n.x * rect.width,
                y: rect.origin.y + n.y * rect.height
            )
        }
        return map
    }
}

// MARK: - Decorations

private struct SilhouetteCardBackground: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                .fill(Color(hex: "#14121D"))

            RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DS.Colors.violet.opacity(0.18),
                            DS.Colors.pink.opacity(0.08)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 88, height: 118)
    }
}

private struct MatchDots: View {
    let score: Double // 0...1

    var body: some View {
        let filled = Int(round(max(0, min(1, score)) * 4))
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < filled ? DS.Colors.pink : Color.white.opacity(0.25))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.35), in: Capsule())
    }
}

private struct SkeletonCardShimmer: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 12.5, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(width: 88, height: 118)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.12), location: 0.5),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .offset(x: phase * 120)
                .mask(RoundedRectangle(cornerRadius: 12.5, style: .continuous))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private struct PulsingSparkle: View {
    @State private var pulse: Bool = false

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(DS.Colors.pink)
            .opacity(pulse ? 0.4 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct FallbackBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DS.Colors.gold)
            Text(LocalizedStringKey(text))
                .font(.system(size: 11, weight: .medium))
                .tracking(-0.1)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(DS.Colors.gold.opacity(0.25), lineWidth: 0.5))
    }
}
