import Foundation

/// Lightweight localization helpers so call sites that can't use
/// SwiftUI's `Text(LocalizedStringKey)` (format strings, computed labels,
/// notifications, etc.) stay terse.
extension String {
    /// Returns the localized variant of `self`, keyed by itself.
    /// Missing keys fall back to the English source text.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Look up a format-string by key and interpolate arguments.
    static func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
