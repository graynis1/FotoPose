import CoreLocation
import Foundation

/// Approximate solar position (altitude/azimuth) and golden/blue hour windows.
/// NOAA-derived formulas, accurate to ~1° for photography purposes.
extension CLLocation {
    struct SunPosition {
        /// Sun altitude in degrees above the horizon. Negative = below horizon.
        let altitude: Double
        /// Azimuth in degrees, measured clockwise from north.
        let azimuth: Double
    }

    enum LightWindow: String {
        case goldenHour
        case blueHour
        case daylight
        case night

        var label: String {
            switch self {
            case .goldenHour: return "Golden Hour"
            case .blueHour:   return "Blue Hour"
            case .daylight:   return "Daylight"
            case .night:      return "Night"
            }
        }

        var emoji: String {
            switch self {
            case .goldenHour: return "🌅"
            case .blueHour:   return "🌆"
            case .daylight:   return "☀️"
            case .night:      return "🌙"
            }
        }
    }

    func sunPosition(at date: Date = Date()) -> SunPosition {
        Self.sunPosition(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            date: date
        )
    }

    func lightWindow(at date: Date = Date()) -> LightWindow {
        let altitude = sunPosition(at: date).altitude
        switch altitude {
        case 6...:        return .daylight
        case -4..<6:      return .goldenHour
        case -6..<(-4):   return .blueHour
        default:          return .night
        }
    }

    /// Returns the next golden-hour start date from `reference`, or nil if none within 48h.
    func nextGoldenHourStart(from reference: Date = Date()) -> Date? {
        let step: TimeInterval = 60
        var cursor = reference
        var wasBelow = sunPosition(at: cursor).altitude < -4 || sunPosition(at: cursor).altitude >= 6
        let limit = reference.addingTimeInterval(48 * 3600)
        while cursor < limit {
            cursor.addTimeInterval(step)
            let alt = sunPosition(at: cursor).altitude
            let isGolden = alt >= -4 && alt < 6
            if isGolden && wasBelow { return cursor }
            wasBelow = !isGolden
        }
        return nil
    }

    // MARK: - Core solar math

    static func sunPosition(latitude: Double, longitude: Double, date: Date) -> SunPosition {
        let jd = julianDay(from: date)
        let n = jd - 2451545.0
        let L = normalizeDegrees(280.460 + 0.9856474 * n)
        let g = normalizeDegrees(357.528 + 0.9856003 * n)
        let gRad = g * .pi / 180
        let lambda = L + 1.915 * sin(gRad) + 0.020 * sin(2 * gRad)
        let lambdaRad = lambda * .pi / 180
        let epsilon = (23.439 - 0.0000004 * n) * .pi / 180

        let ra = atan2(cos(epsilon) * sin(lambdaRad), cos(lambdaRad))
        let dec = asin(sin(epsilon) * sin(lambdaRad))

        let gmst = normalizeDegrees(280.46061837 + 360.98564736629 * n)
        let lmst = normalizeDegrees(gmst + longitude)
        let lmstRad = lmst * .pi / 180
        let hourAngle = lmstRad - ra

        let latRad = latitude * .pi / 180
        let altitude = asin(sin(latRad) * sin(dec) + cos(latRad) * cos(dec) * cos(hourAngle))
        let azimuth = atan2(
            -sin(hourAngle),
            tan(dec) * cos(latRad) - sin(latRad) * cos(hourAngle)
        )

        return SunPosition(
            altitude: altitude * 180 / .pi,
            azimuth: normalizeDegrees(azimuth * 180 / .pi)
        )
    }

    private static func julianDay(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        let m = value.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }
}
