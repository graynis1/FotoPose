import Foundation
import CoreGraphics

// MARK: - Normalized geometry

/// A keypoint in 0...1 image coordinates with top-left origin (matches our
/// Vision pipeline after the y-flip in VisionService).
struct NormalizedPoint: Codable, Hashable {
    let x: Double
    let y: Double

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    static let zero = NormalizedPoint(x: 0, y: 0)
}

// MARK: - Skeleton

/// 15-joint skeleton that can be drawn as a silhouette and compared against a
/// live Vision body pose. Includes head + neck (previously missing) so we can
/// draw a proper portrait silhouette.
struct PoseKeypoints: Codable, Hashable {
    let head: NormalizedPoint
    let neck: NormalizedPoint
    let leftShoulder: NormalizedPoint
    let rightShoulder: NormalizedPoint
    let leftElbow: NormalizedPoint
    let rightElbow: NormalizedPoint
    let leftWrist: NormalizedPoint
    let rightWrist: NormalizedPoint
    let leftHip: NormalizedPoint
    let rightHip: NormalizedPoint
    let leftKnee: NormalizedPoint
    let rightKnee: NormalizedPoint
    let leftAnkle: NormalizedPoint
    let rightAnkle: NormalizedPoint

    /// Canonical joint-key strings — align with Vision joint names so overlay
    /// comparison is a pure dictionary lookup.
    enum Key: String, CaseIterable {
        case head, neck
        case leftShoulder = "left_shoulder"
        case rightShoulder = "right_shoulder"
        case leftElbow = "left_elbow"
        case rightElbow = "right_elbow"
        case leftWrist = "left_wrist"
        case rightWrist = "right_wrist"
        case leftHip = "left_hip"
        case rightHip = "right_hip"
        case leftKnee = "left_knee"
        case rightKnee = "right_knee"
        case leftAnkle = "left_ankle"
        case rightAnkle = "right_ankle"
    }

    /// Bones rendered as line segments between pairs of joints.
    static let bones: [(Key, Key)] = [
        (.head, .neck),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    /// Dictionary-style lookup — handy for the overlay that compares every
    /// target joint against its Vision counterpart.
    func point(_ key: Key) -> NormalizedPoint {
        switch key {
        case .head:           return head
        case .neck:           return neck
        case .leftShoulder:   return leftShoulder
        case .rightShoulder:  return rightShoulder
        case .leftElbow:      return leftElbow
        case .rightElbow:     return rightElbow
        case .leftWrist:      return leftWrist
        case .rightWrist:     return rightWrist
        case .leftHip:        return leftHip
        case .rightHip:       return rightHip
        case .leftKnee:       return leftKnee
        case .rightKnee:      return rightKnee
        case .leftAnkle:      return leftAnkle
        case .rightAnkle:     return rightAnkle
        }
    }

    /// Neutral standing silhouette used as a placeholder / shimmer skeleton.
    static let standing = PoseKeypoints(
        head:          NormalizedPoint(x: 0.50, y: 0.10),
        neck:          NormalizedPoint(x: 0.50, y: 0.18),
        leftShoulder:  NormalizedPoint(x: 0.40, y: 0.22),
        rightShoulder: NormalizedPoint(x: 0.60, y: 0.22),
        leftElbow:     NormalizedPoint(x: 0.36, y: 0.38),
        rightElbow:    NormalizedPoint(x: 0.64, y: 0.38),
        leftWrist:     NormalizedPoint(x: 0.34, y: 0.53),
        rightWrist:    NormalizedPoint(x: 0.66, y: 0.53),
        leftHip:       NormalizedPoint(x: 0.44, y: 0.56),
        rightHip:      NormalizedPoint(x: 0.56, y: 0.56),
        leftKnee:      NormalizedPoint(x: 0.44, y: 0.76),
        rightKnee:     NormalizedPoint(x: 0.56, y: 0.76),
        leftAnkle:     NormalizedPoint(x: 0.44, y: 0.95),
        rightAnkle:    NormalizedPoint(x: 0.56, y: 0.95)
    )
}

// MARK: - GeneratedPose

/// A pose produced at runtime by PoseAIEngine or PoseFallbackEngine.
/// Every pose the user sees is a value of this type — no static catalog.
struct GeneratedPose: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    /// `PoseCategory.rawValue` when mappable, or a free-form string otherwise.
    let category: String
    /// `Difficulty.rawValue` when mappable, or a free-form string otherwise.
    let difficulty: String
    let tips: [String]
    let bodyKeypoints: PoseKeypoints
    /// 0...1 — how well this pose matches the current scene / lighting.
    let matchScore: Double
    /// True when this pose is served by the fallback engine (iOS <26 / unsupported device).
    var isFallback: Bool = false
    /// Optional — populated by the fallback templates so the rule-based engine can filter.
    var personCount: Int = 1
    var suitableLighting: [Lighting] = []
    var suitableScene: [Scene] = []
    var isPro: Bool = false

    var categoryDisplayName: String {
        PoseCategory(rawValue: category)?.displayName ?? category.capitalized
    }

    var difficultyLabel: String {
        Difficulty(rawValue: difficulty)?.effortLabel ?? difficulty.capitalized
    }
}

// MARK: - Context

/// Snapshot handed to PoseAIEngine.generatePoses — everything the model needs
/// to produce suggestions tailored to the live scene.
struct PoseContext: Equatable {
    var personCount: Int
    var estimatedGender: String        // "female", "male", "any"
    var estimatedBodyType: String      // "slim", "athletic", "average", "curvy", "any"
    var currentPosture: String         // "standing", "sitting", …
    var sceneType: String              // "beach", "park", "indoor", …
    var lightingCondition: String      // "goldenHour", "studio", …
    /// Fused camera white-balance Kelvin value — drives the >500K regeneration trigger.
    var colorTemperature: Double
    var timeOfDay: String              // "Golden Hour", "Midday", …
    var isGoldenHour: Bool
    /// Free-form user query — plumbed from the Library search field.
    var userQuery: String = ""
    /// Optional category hint — set when the user taps a category tile in Library.
    var categoryHint: String = ""
}

extension PoseContext {
    /// Builds a context from the live DetectionResult. Gender/body-type stay
    /// `any` until we wire a classifier — the AI still uses the other signals.
    static func from(detection: DetectionResult) -> PoseContext {
        PoseContext(
            personCount: max(1, detection.personCount),
            estimatedGender: detection.detectedGender.rawValue,
            estimatedBodyType: detection.detectedBodyType.rawValue,
            currentPosture: detection.currentPosture.rawValue,
            sceneType: detection.detectedScene.rawValue,
            lightingCondition: detection.detectedLighting.rawValue,
            colorTemperature: 0,
            timeOfDay: detection.timeOfDay,
            isGoldenHour: detection.detectedLighting == .goldenHour
        )
    }

    /// Signals that should bust the 15-20s debounce immediately.
    func majorDelta(from other: PoseContext) -> Bool {
        if personCount != other.personCount { return true }
        if sceneType != other.sceneType { return true }
        if abs(colorTemperature - other.colorTemperature) > 500 { return true }
        return false
    }
}
