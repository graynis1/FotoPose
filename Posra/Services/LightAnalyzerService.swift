import CoreLocation
import CoreMedia
import Foundation

/// Combines camera sensor readings (ISO, WB Kelvin, exposure duration)
/// with astronomical sun position to infer a higher-fidelity lighting type.
/// Indoor-vs-outdoor is inferred separately (by SceneClassifierService);
/// the caller supplies that hint so this class doesn't guess twice.
struct LightAnalyzerService {
    struct Reading {
        let iso: Float
        let kelvin: Float
        let exposureSeconds: Double
        /// Scene brightness value (Apple's APEX-like proxy). Higher = brighter.
        var brightness: Double {
            guard exposureSeconds > 0, iso > 0 else { return 0 }
            // Higher ISO or longer exposure → darker scene. Invert to get brightness.
            return log2(1.0 / (exposureSeconds * Double(iso) / 100.0))
        }
    }

    /// Classifies lighting. Uses astronomical twilight data if a location is present.
    /// - Parameters:
    ///   - reading: latest camera sensor reading
    ///   - location: user's location (optional; enables golden/blue hour precision)
    ///   - scene: inferred scene (optional; `.indoor`/`.studio` skip sun lookup)
    ///   - date: for testability
    func classify(reading: Reading,
                  location: CLLocation?,
                  scene: Scene = .any,
                  date: Date = Date()) -> Lighting {
        // Indoor paths — rely on Kelvin and ISO.
        if scene == .indoor || scene == .studio {
            return classifyIndoor(reading: reading)
        }

        // Outdoor: defer to the sun when we have a location.
        if let location {
            switch location.lightWindow(at: date) {
            case .goldenHour: return .goldenHour
            case .blueHour:   return .blueHour
            case .night:      return .night
            case .daylight:
                return classifyDaylight(reading: reading)
            }
        }

        // No location — fall back to Kelvin + brightness heuristics.
        return classifyWithoutLocation(reading: reading, date: date)
    }

    /// Textual label for the lighting, suitable for the environment chip.
    static func label(for lighting: Lighting) -> (emoji: String, title: String) {
        switch lighting {
        case .goldenHour: return ("🌅", "Golden Hour".localized)
        case .blueHour:   return ("🌆", "Blue Hour".localized)
        case .softLight:  return ("🌤️", "Soft Light".localized)
        case .harsh:      return ("☀️", "Harsh Light".localized)
        case .night:      return ("🌙", "Night".localized)
        case .studio:     return ("💡", "Studio".localized)
        case .any:        return ("📷", "Mixed Light".localized)
        }
    }

    // MARK: - Private helpers

    private func classifyIndoor(reading: Reading) -> Lighting {
        // ≤3500 K → tungsten/warm indoor → studio bias.
        // 4000–5500 K → LED/daylight balanced → soft light.
        // >5500 K → windowed indoor → soft light too.
        if reading.kelvin <= 3500 { return .studio }
        return .softLight
    }

    private func classifyDaylight(reading: Reading) -> Lighting {
        // Bright + cool → likely midday harsh.
        // Cool + lower brightness → soft cloudy.
        let brightness = reading.brightness
        if reading.kelvin >= 6000 && brightness >= 10 { return .harsh }
        return .softLight
    }

    private func classifyWithoutLocation(reading: Reading, date: Date) -> Lighting {
        let hour = Calendar.current.component(.hour, from: date)
        let brightness = reading.brightness

        if brightness < 3 { return .night }

        switch reading.kelvin {
        case ..<3000:
            return .studio
        case 3000..<4500:
            if hour >= 5 && hour <= 7 { return .goldenHour }
            if hour >= 17 && hour <= 20 { return .goldenHour }
            return .softLight
        case 4500..<6000:
            return .softLight
        case 6000..<7500:
            return brightness >= 10 ? .harsh : .softLight
        default:
            return .blueHour
        }
    }
}
