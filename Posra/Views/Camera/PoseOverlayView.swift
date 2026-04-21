import SwiftUI

/// Renders the AR guide silhouette from a `GeneratedPose.bodyKeypoints`, compares
/// every joint against the live Vision pose, and transitions the stroke color
/// from violet/pink toward green as the subject aligns with the guide.
/// Reports the overall alignment score (0...1) back to the parent view via
/// `onAlignmentChange` so the view model can flash "Perfect!" + haptic.
struct PoseOverlayView: View {
    let targetKeypoints: PoseKeypoints
    /// Detected person bounding box in normalized view coords (top-left origin).
    let subjectRect: CGRect?
    /// Live detected skeleton, drawn subtly under the guide for feedback.
    let liveBodyPose: BodyPoseObservation?
    var baseOpacity: Double = 0.6
    var onAlignmentChange: (Double) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rect = effectiveRect(in: size)
            let alignment = computeAlignment(targetRect: rect, viewSize: size)

            ZStack {
                GuideSkeleton(
                    keypoints: targetKeypoints,
                    rect: rect,
                    alignment: alignment
                )
                .opacity(baseOpacity + 0.15 * alignment)

                if let live = liveBodyPose {
                    LiveSkeleton(pose: live, viewSize: size)
                        .opacity(0.3 + 0.25 * (1 - alignment))
                }
            }
            .onAppear { onAlignmentChange(alignment) }
            .onChange(of: alignmentBucket(alignment)) { _ in
                onAlignmentChange(alignment)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Geometry

    private func effectiveRect(in viewSize: CGSize) -> CGRect {
        if let subjectRect {
            let expanded = subjectRect.insetBy(dx: -subjectRect.width * 0.1,
                                               dy: -subjectRect.height * 0.1)
            return CGRect(
                x: expanded.origin.x * viewSize.width,
                y: expanded.origin.y * viewSize.height,
                width: expanded.width * viewSize.width,
                height: expanded.height * viewSize.height
            )
        }
        let w = viewSize.width * 0.55
        let h = viewSize.height * 0.72
        return CGRect(
            x: (viewSize.width - w) / 2,
            y: (viewSize.height - h) / 2 - viewSize.height * 0.06,
            width: w,
            height: h
        )
    }

    // MARK: - Alignment scoring

    /// Per-joint distance in view-space normalized by the shorter view dimension.
    /// Returns 0...1 where 1.0 means the live pose matches the target perfectly.
    private func computeAlignment(targetRect: CGRect, viewSize: CGSize) -> Double {
        guard let live = liveBodyPose, !live.joints.isEmpty else { return 0 }
        let diag = Double(hypot(viewSize.width, viewSize.height))
        guard diag > 0 else { return 0 }

        var total: Double = 0
        var count: Int = 0
        for key in PoseKeypoints.Key.allCases {
            guard let liveJoint = live.joints[key.rawValue] else { continue }
            let target = targetKeypoints.point(key)
            let targetPos = CGPoint(
                x: targetRect.origin.x + target.x * targetRect.width,
                y: targetRect.origin.y + target.y * targetRect.height
            )
            let livePos = CGPoint(x: liveJoint.position.x * viewSize.width,
                                  y: liveJoint.position.y * viewSize.height)
            let d = Double(hypot(targetPos.x - livePos.x, targetPos.y - livePos.y))
            // Map distance → per-joint score: 0.08*diag → 1.0, 0.30*diag → 0.
            let normalized = max(0, 1 - (d / (diag * 0.25)))
            total += normalized
            count += 1
        }
        guard count >= 6 else { return 0 } // not enough joints visible — skip
        return min(1, max(0, total / Double(count)))
    }

    /// Buckets alignment to avoid rebuilding onAlignmentChange on every pixel of drift.
    private func alignmentBucket(_ value: Double) -> Int { Int(value * 20) }
}

// MARK: - Guide skeleton

private struct GuideSkeleton: View {
    let keypoints: PoseKeypoints
    let rect: CGRect
    /// 0...1 — drives the color lerp from violet/pink to green.
    let alignment: Double

    var body: some View {
        let pts = mappedPoints()
        let stroke = strokeStyle(for: alignment)

        return ZStack {
            // Bones
            Path { path in
                for (a, b) in PoseKeypoints.bones {
                    let p1 = pts[a.rawValue] ?? .zero
                    let p2 = pts[b.rawValue] ?? .zero
                    path.move(to: p1)
                    path.addLine(to: p2)
                }
            }
            .stroke(
                stroke,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: glowColor(for: alignment).opacity(0.5), radius: 6)

            // Head circle
            if let head = pts[PoseKeypoints.Key.head.rawValue] {
                Circle()
                    .stroke(stroke, lineWidth: 2.5)
                    .frame(width: rect.width * 0.22, height: rect.width * 0.22)
                    .position(head)
                    .shadow(color: glowColor(for: alignment).opacity(0.45), radius: 6)
            }

            // Joint dots
            ForEach(PoseKeypoints.Key.allCases, id: \.self) { key in
                if let p = pts[key.rawValue] {
                    ZStack {
                        Circle()
                            .fill(glowColor(for: alignment).opacity(0.6))
                            .frame(width: 12, height: 12)
                            .blur(radius: 2)
                        Circle()
                            .fill(.white)
                            .frame(width: 5, height: 5)
                    }
                    .position(p)
                }
            }
        }
    }

    private func mappedPoints() -> [String: CGPoint] {
        var map: [String: CGPoint] = [:]
        for key in PoseKeypoints.Key.allCases {
            let n = keypoints.point(key)
            map[key.rawValue] = CGPoint(
                x: rect.origin.x + n.x * rect.width,
                y: rect.origin.y + n.y * rect.height
            )
        }
        return map
    }

    private func strokeStyle(for alignment: Double) -> AnyShapeStyle {
        if alignment >= 0.85 {
            return AnyShapeStyle(LinearGradient(
                colors: [DS.Colors.green, DS.Colors.green.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        // Lerp the accent gradient toward green as alignment grows.
        let top = Color.lerp(from: DS.Colors.violet, to: DS.Colors.green, amount: alignment)
        let bottom = Color.lerp(from: DS.Colors.pink, to: DS.Colors.green, amount: alignment)
        return AnyShapeStyle(LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ))
    }

    private func glowColor(for alignment: Double) -> Color {
        alignment >= 0.85 ? DS.Colors.green : DS.Colors.pink
    }
}

// MARK: - Live skeleton (subtle white)

private struct LiveSkeleton: View {
    let pose: BodyPoseObservation
    let viewSize: CGSize

    var body: some View {
        Path { path in
            for (a, b) in BodyPoseObservation.skeletonSegments {
                if let p1 = pose.joints[a]?.position, let p2 = pose.joints[b]?.position {
                    path.move(to: CGPoint(x: p1.x * viewSize.width, y: p1.y * viewSize.height))
                    path.addLine(to: CGPoint(x: p2.x * viewSize.width, y: p2.y * viewSize.height))
                }
            }
        }
        .stroke(Color.white,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }
}

// MARK: - Rule-of-thirds grid

struct RuleOfThirdsGrid: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let w = proxy.size.width
                let h = proxy.size.height
                let xs = [w / 3, 2 * w / 3]
                let ys = [h / 3, 2 * h / 3]
                for x in xs {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: h))
                }
                for y in ys {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Color lerp helper

extension Color {
    static func lerp(from a: Color, to b: Color, amount: Double) -> Color {
        let t = max(0, min(1, amount))
        let ac = UIColor(a).rgba
        let bc = UIColor(b).rgba
        return Color(
            red: ac.r + (bc.r - ac.r) * t,
            green: ac.g + (bc.g - ac.g) * t,
            blue: ac.b + (bc.b - ac.b) * t,
            opacity: ac.a + (bc.a - ac.a) * t
        )
    }
}

private extension UIColor {
    var rgba: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
