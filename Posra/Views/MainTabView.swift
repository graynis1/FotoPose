import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .camera:
                    CameraView()
                case .library:
                    LibraryView()
                case .settings:
                    SettingsView()
                }
            }
            .ignoresSafeArea()

            PosraTabBar(selected: $appState.selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
    }
}

struct PosraTabBar: View {
    @Binding var selected: AppState.MainTab

    var body: some View {
        HStack(spacing: 0) {
            tab(icon: "camera.fill", label: "Camera", tab: .camera)
            tab(icon: "square.grid.2x2.fill", label: "Library", tab: .library)
            tab(icon: "gearshape.fill", label: "Settings", tab: .settings)
        }
        .frame(height: 62)
        .padding(.horizontal, 6)
        .glass(
            tint: Color.black.opacity(0.35),
            borderOpacity: 0.12,
            cornerRadius: 26
        )
    }

    @ViewBuilder
    private func tab(icon: String, label: String, tab: AppState.MainTab) -> some View {
        let isActive = selected == tab
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive
                                     ? AnyShapeStyle(DS.Gradients.accent)
                                     : AnyShapeStyle(Color.white.opacity(0.45)))
                Text(LocalizedStringKey(label))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isActive ? DS.Colors.textPrimary : DS.Colors.textDisabled)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService())
}
