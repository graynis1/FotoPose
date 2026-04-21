import Foundation
import CoreGraphics

struct DetectionResult: Equatable {
    var personCount: Int = 0
    var currentPosture: Posture = .unknown
    var detectedGender: Gender = .any
    var detectedBodyType: BodyType = .any
    var detectedScene: Scene = .any
    var detectedLighting: Lighting = .any
    var timeOfDay: String = ""
    var framingQuality: FramingQuality = .unknown
    var poseMatchConfidence: Double = 0 // 0...1
}

enum Posture: String {
    case unknown
    case standing
    case sitting
    case crouching
    case leaning
}

enum FramingQuality: String {
    case unknown
    case poor
    case good
    case excellent
}

struct BodyPoseObservation {
    struct Joint {
        let name: String
        /// Normalized coords (0...1), top-left origin (AVFoundation/view coords).
        let position: CGPoint
        let confidence: Float
    }
    let joints: [String: Joint]

    /// Returns joints as (start, end) pairs for skeleton line drawing.
    /// Joint keys match `PoseKeypoints.Key.rawValue` + "head"/"neck".
    static let skeletonSegments: [(String, String)] = [
        ("head", "neck"),
        ("neck", "left_shoulder"),
        ("neck", "right_shoulder"),
        ("left_shoulder", "left_elbow"),
        ("left_elbow", "left_wrist"),
        ("right_shoulder", "right_elbow"),
        ("right_elbow", "right_wrist"),
        ("left_shoulder", "left_hip"),
        ("right_shoulder", "right_hip"),
        ("left_hip", "right_hip"),
        ("left_hip", "left_knee"),
        ("left_knee", "left_ankle"),
        ("right_hip", "right_knee"),
        ("right_knee", "right_ankle")
    ]
}
