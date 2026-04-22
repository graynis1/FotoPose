import SwiftUI

enum DS {

    // MARK: - Colors

    enum Colors {
        static let background = Color(hex: "#0A0A0F")
        static let cardBackground = Color(hex: "#0F0B18")

        static let violet = Color(hex: "#A78BFA")
        static let pink = Color(hex: "#EC4899")
        static let pinkDeep = Color(hex: "#DB2777")
        static let pinkSoft = Color(hex: "#F472B6")

        static let green = Color(hex: "#10B981")
        static let gold = Color(hex: "#FBBF24")
        static let red = Color(hex: "#EF4444")

        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.72)
        static let textTertiary = Color.white.opacity(0.55)
        static let textDisabled = Color.white.opacity(0.45)
        static let textLabel = Color.white.opacity(0.30)

        static let glassFill = Color.white.opacity(0.06)
        static let glassBorder = Color.white.opacity(0.10)

        static let divider = Color.white.opacity(0.08)
    }

    // MARK: - Gradients

    enum Gradients {
        static let accent = LinearGradient(
            colors: [Colors.violet, Colors.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accentHorizontal = LinearGradient(
            colors: [Colors.violet, Colors.pink],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let accentSoft = LinearGradient(
            colors: [Colors.violet.opacity(0.18), Colors.pink.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let topDarken = LinearGradient(
            colors: [Color.black.opacity(0.55), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )

        static let bottomDarken = LinearGradient(
            colors: [Color.clear, Colors.background.opacity(0.98)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let cardShadow = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Radii

    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 14
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 24
        static let small: CGFloat = 10
        static let xsmall: CGFloat = 7
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // MARK: - Typography

    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}
