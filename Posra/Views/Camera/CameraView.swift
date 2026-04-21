import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var detailPose: GeneratedPose? = nil

    var body: some View {
        ZStack {
            if viewModel.isAuthorized {
                CameraPreviewView(session: viewModel.cameraService.session)
                    .ignoresSafeArea()
            } else {
                CameraPermissionEmptyState()
            }

            RuleOfThirdsGrid()
                .ignoresSafeArea()

            PoseOverlayView(
                targetKeypoints: viewModel.selectedPose?.bodyKeypoints ?? PoseKeypoints.standing,
                subjectRect: viewModel.subjectRect,
                liveBodyPose: viewModel.bodyPose,
                baseOpacity: 0.55,
                onAlignmentChange: { viewModel.reportAlignment($0) }
            )
            .ignoresSafeArea()

            // Top gradient
            LinearGradient(colors: [Color.black.opacity(0.55), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 170)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Bottom gradient
            LinearGradient(colors: [.clear, Color.black.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 360)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // HUD
            VStack(spacing: 0) {
                topBar
                Spacer()
                coachingHint
                Spacer().frame(height: 14)
                PoseCardCarousel(
                    poses: viewModel.suggestedPoses,
                    selectedID: viewModel.selectedPoseID,
                    isLoading: viewModel.isGenerating,
                    fallbackBanner: viewModel.fallbackBanner,
                    onSelect: { pose in
                        if pose.isPro && !subscriptionService.status.isPro {
                            appState.presentPaywall()
                            return
                        }
                        viewModel.select(poseID: pose.id)
                    },
                    onDetail: { pose in detailPose = pose },
                    onRefresh: { viewModel.refreshRequested() },
                    onSeeAll: { appState.selectedTab = .library }
                )
                modeStrip
                    .padding(.top, 12)
                shutterRow
                    .padding(.top, 14)
                Spacer().frame(height: 86)
            }
            .padding(.top, 4)

            // Perfect alignment flash
            if viewModel.perfectMoment {
                PerfectFlash()
                    .allowsHitTesting(false)
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(item: $detailPose) { pose in
            PoseDetailSheet(
                pose: pose,
                detection: viewModel.detection,
                similar: similarPoses(to: pose),
                onUsePose: { viewModel.select(poseID: pose.id) },
                onDismiss: { detailPose = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#0E0E14"))
        }
    }

    private func similarPoses(to pose: GeneratedPose) -> [GeneratedPose] {
        let pool = viewModel.suggestedPoses + PoseHistoryService.shared.favorites + PoseFallbackEngine.all
        return pool
            .filter { $0.id != pose.id && $0.category == pose.category }
            .prefix(4)
            .map { $0 }
    }

    // MARK: - HUD sections

    private var topBar: some View {
        HStack(alignment: .top) {
            EnvironmentTagView(detection: viewModel.detection)
            Spacer()
            HStack(spacing: 10) {
                iconButton(system: viewModel.flashEnabled ? "bolt.fill" : "bolt.slash.fill") {
                    viewModel.toggleFlash()
                }
                iconButton(system: "timer") {
                    viewModel.cyclTimer()
                }
                iconButton(system: "camera.rotate.fill") {
                    viewModel.switchCamera()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .overlay(alignment: .topTrailing) {
            DetectionChipsColumn(detection: viewModel.detection)
                .padding(.top, 54)
                .padding(.trailing, 18)
        }
    }

    private var coachingHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.Gradients.accent)
            Text(LocalizedStringKey(coachingText))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glass(tint: Color.black.opacity(0.5), borderOpacity: 0.15)
        .padding(.bottom, 4)
    }

    private var coachingText: String {
        if viewModel.detection.personCount == 0 {
            return "Point at a subject to begin"
        }
        if viewModel.alignmentScore >= 0.85 {
            return "Perfect — hold it right there"
        }
        if viewModel.alignmentScore >= 0.6 {
            return "Almost there — match the guide"
        }
        switch viewModel.detection.framingQuality {
        case .poor: return "Step closer — frame your subject"
        case .good: return "Tilt your chin slightly up — match the guide"
        case .excellent: return "Hold the pose — match the skeleton"
        case .unknown: return "Looking for your subject…"
        }
    }

    private var modeStrip: some View {
        HStack(spacing: 22) {
            modeLabel("VIDEO", selected: false)
            modeLabel("PHOTO", selected: true)
            modeLabel("PORTRAIT", selected: false)
        }
    }

    private func modeLabel(_ text: String, selected: Bool) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 11, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(selected ? DS.Colors.pink : Color.white.opacity(0.5))
    }

    private var shutterRow: some View {
        HStack {
            ZStack {
                if let image = viewModel.lastCapturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.6))
                        )
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            )
            .frame(maxWidth: .infinity)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.shutterPressed()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(.white)
                        .frame(width: 62, height: 62)
                    if viewModel.timerSeconds > 0 {
                        Text(String.localized("settings.seconds", viewModel.timerSeconds))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Button {
                viewModel.refreshRequested()
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .glass(tint: Color.black.opacity(0.4),
                       borderOpacity: 0.15,
                       cornerRadius: 17)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Perfect flash

private struct PerfectFlash: View {
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DS.Colors.green)
                Text("Perfect!")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().stroke(DS.Colors.green.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: DS.Colors.green.opacity(0.5), radius: 20, x: 0, y: 0)
            .offset(y: -220)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    opacity = 1
                }
                withAnimation(.easeOut(duration: 0.35).delay(0.5)) {
                    opacity = 0
                }
            }
            Spacer()
        }
    }
}

// MARK: - Permission empty state

private struct CameraPermissionEmptyState: View {
    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(DS.Gradients.accent)
                Text("Camera access needed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enable camera permission in Settings to start using FotoPose.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.horizontal, 40)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(GradientButtonStyle(height: 46, cornerRadius: 23))
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService())
}
