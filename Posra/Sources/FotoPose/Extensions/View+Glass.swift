import SwiftUI

struct GlassBackground: ViewModifier {
    var tint: Color = Color.white.opacity(0.06)
    var borderOpacity: Double = 0.10
    var cornerRadius: CGFloat = DS.Radius.pill

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GradientBorder: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat = 1.5
    var gradient: LinearGradient = DS.Gradients.accent

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(gradient, lineWidth: lineWidth)
            )
    }
}

extension View {
    func glass(
        tint: Color = Color.white.opacity(0.06),
        borderOpacity: Double = 0.10,
        cornerRadius: CGFloat = DS.Radius.pill
    ) -> some View {
        modifier(GlassBackground(tint: tint, borderOpacity: borderOpacity, cornerRadius: cornerRadius))
    }

    func gradientBorder(
        cornerRadius: CGFloat,
        lineWidth: CGFloat = 1.5,
        gradient: LinearGradient = DS.Gradients.accent
    ) -> some View {
        modifier(GradientBorder(cornerRadius: cornerRadius, lineWidth: lineWidth, gradient: gradient))
    }
}

struct GradientButtonStyle: ButtonStyle {
    var height: CGFloat = 54
    var cornerRadius: CGFloat = 27

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(DS.Gradients.accent)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: DS.Colors.pink.opacity(0.5), radius: 14, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                    .mask(
                        LinearGradient(
                            colors: [Color.white, Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
