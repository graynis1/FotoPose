import Foundation
import CoreGraphics

// Shared taxonomy used by detection / analysis services and by GeneratedPose.
// The concrete Pose struct and its static catalog were removed — every pose the
// user sees now comes from PoseAIEngine (or PoseFallbackEngine on older devices).

enum PoseCategory: String, Codable, CaseIterable {
    case portrait
    case streetStyle
    case couple
    case editorial
    case wedding
    case group
    case sitting
    case action
    case fullBody

    var displayName: String {
        switch self {
        case .portrait: return "Classic Portrait".localized
        case .streetStyle: return "Street Style".localized
        case .couple: return "Couple".localized
        case .editorial: return "Editorial".localized
        case .wedding: return "Wedding".localized
        case .group: return "Group".localized
        case .sitting: return "Sitting".localized
        case .action: return "Action".localized
        case .fullBody: return "Full Body".localized
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard

    var effortLabel: String {
        switch self {
        case .easy: return "Low effort".localized
        case .medium: return "Medium effort".localized
        case .hard: return "High effort".localized
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case female, male, any
}

enum BodyType: String, Codable, CaseIterable {
    case slim, athletic, average, curvy, any
}

enum Lighting: String, Codable, CaseIterable {
    case goldenHour, blueHour, softLight, harsh, night, studio, any
}

enum Scene: String, Codable, CaseIterable {
    case outdoor, park, city, beach, indoor, studio, any
}
