import SwiftUI

struct EnvironmentTagView: View {
    let detection: DetectionResult

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DS.Colors.green)
                .frame(width: 6, height: 6)
                .shadow(color: DS.Colors.green, radius: 4)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .tracking(-0.1)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glass(tint: Color.black.opacity(0.4), borderOpacity: 0.12)
    }

    private var label: String {
        let light = LightAnalyzerService.label(for: detection.detectedLighting)
        let scene = Self.sceneLabel(detection.detectedScene)

        var leading = ""
        if !light.emoji.isEmpty { leading = "\(light.emoji) " }

        var pieces: [String] = []
        if detection.detectedScene != .any { pieces.append(scene) }
        if detection.detectedLighting != .any { pieces.append(light.title) }
        if pieces.isEmpty { pieces.append("Analyzing…".localized) }
        return leading + pieces.joined(separator: " · ")
    }

    private static func sceneLabel(_ scene: Scene) -> String {
        switch scene {
        case .any:     return "Scene".localized
        case .outdoor: return "Outdoor".localized
        case .park:    return "Park".localized
        case .city:    return "City".localized
        case .beach:   return "Beach".localized
        case .indoor:  return "Indoor".localized
        case .studio:  return "Studio".localized
        }
    }
}

struct DetectionChipsColumn: View {
    let detection: DetectionResult

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            let personKey = detection.personCount == 1 ? "detection.person.one" : "detection.person.many"
            chip(dot: DS.Colors.pink,
                 text: String.localized(personKey, detection.personCount))
            chip(dot: DS.Colors.violet,
                 text: String.localized("detection.poseMatch", Int(detection.poseMatchConfidence * 100)))
            chip(dot: framingColor,
                 text: String.localized("detection.framing", detection.framingQuality.rawValue.localized))
            if !detection.timeOfDay.isEmpty {
                chip(dot: DS.Colors.green, text: detection.timeOfDay.localized)
            }
        }
    }

    private func chip(dot: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 10.5, weight: .medium))
                .tracking(-0.1)
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .glass(tint: Color.black.opacity(0.45), borderOpacity: 0.12)
    }

    private var framingColor: Color {
        switch detection.framingQuality {
        case .excellent, .good: return DS.Colors.green
        case .poor: return DS.Colors.pink
        case .unknown: return Color.white.opacity(0.4)
        }
    }
}
