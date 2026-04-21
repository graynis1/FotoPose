import Foundation
import SwiftUI
import AVFoundation
import CoreMedia
import Combine
import CoreLocation

@MainActor
final class CameraViewModel: ObservableObject {
    // Input / output services
    let cameraService = CameraService()
    private let visionService = VisionService()
    private let sceneClassifier = SceneClassifierService()
    private let lightAnalyzer = LightAnalyzerService()
    private let locationService = LocationService()
    private let aiEngine = PoseAIEngine.shared

    // Published state
    @Published var bodyPose: BodyPoseObservation? = nil
    @Published var subjectRect: CGRect? = nil
    @Published var detection: DetectionResult = DetectionResult()
    @Published var suggestedPoses: [GeneratedPose] = []
    @Published var selectedPoseID: String? = nil
    @Published var isAuthorized: Bool = false
    @Published var showPermissionPrompt: Bool = false
    @Published var lastCapturedImage: UIImage? = nil
    @Published var flashEnabled: Bool = false
    @Published var timerSeconds: Int = 0 // 0, 3, 5, 10

    /// True while the engine is producing a fresh batch — UI shows shimmer cards.
    @Published var isGenerating: Bool = false
    /// True when serving from `PoseFallbackEngine` (device doesn't support Foundation Models).
    @Published var isFallbackMode: Bool = false

    /// Skeleton alignment 0...1 — updated by PoseOverlayView via `reportAlignment(_:)`.
    @Published var alignmentScore: Double = 0
    /// Flashes true briefly when alignment passes 85% — CameraView shows "Perfect!".
    @Published var perfectMoment: Bool = false

    private var cancellables: Set<AnyCancellable> = []
    private let receiver = FrameReceiverBridge()
    private var latestLocation: CLLocation?
    private var latestScene: Scene = .any
    private var lastContext: PoseContext?
    private var perfectFlashTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?

    init() {
        cameraService.frameReceiver = receiver
        receiver.onFrame = { [weak self] buffer in
            guard let self else { return }
            self.visionService.process(sampleBuffer: buffer)
            self.sceneClassifier.process(sampleBuffer: buffer)
        }
        visionService.delegate = self
        sceneClassifier.onClassify = { [weak self] scene in
            self?.latestScene = scene
        }

        locationService.$location
            .compactMap { $0 }
            .sink { [weak self] loc in self?.latestLocation = loc }
            .store(in: &cancellables)

        isFallbackMode = !aiEngine.isAvailable
    }

    var selectedPose: GeneratedPose? {
        guard let selectedPoseID else { return suggestedPoses.first }
        return suggestedPoses.first(where: { $0.id == selectedPoseID }) ?? suggestedPoses.first
    }

    /// UI banner text — non-nil only when we're in fallback mode.
    var fallbackBanner: String? {
        isFallbackMode ? PoseFallbackEngine.upgradeBanner : nil
    }

    // MARK: - Session

    func start() {
        cameraService.requestAuthorization { [weak self] granted in
            guard let self else { return }
            self.isAuthorized = granted
            if granted {
                self.cameraService.configureAndStart()
            } else {
                self.showPermissionPrompt = true
            }
        }
        locationService.start()

        // Seed with fallback immediately so the carousel is never empty.
        if suggestedPoses.isEmpty {
            let seed = PoseFallbackEngine.poses(for: currentContext(), limit: 5)
            suggestedPoses = seed
            selectedPoseID = seed.first?.id
        }
        // Fire an async generation attempt — may upgrade the seed with AI output.
        scheduleGeneration(force: true)
    }

    func stop() {
        cameraService.stop()
        locationService.stop()
        generationTask?.cancel()
    }

    func switchCamera() { cameraService.switchCamera() }
    func toggleFlash() { flashEnabled.toggle() }

    func cyclTimer() {
        let sequence = [0, 3, 5, 10]
        if let idx = sequence.firstIndex(of: timerSeconds) {
            timerSeconds = sequence[(idx + 1) % sequence.count]
        } else {
            timerSeconds = 0
        }
    }

    // MARK: - Selection

    func select(poseID: String) {
        selectedPoseID = poseID
        if let pose = suggestedPoses.first(where: { $0.id == poseID }) {
            PoseHistoryService.shared.noteView(pose)
        }
    }

    /// User-initiated refresh (pull / button) — forces a fresh generation.
    func refreshRequested() {
        aiEngine.invalidate()
        scheduleGeneration(force: true)
    }

    // MARK: - Alignment feedback from PoseOverlayView

    func reportAlignment(_ score: Double) {
        alignmentScore = score
        if score >= 0.85, !perfectMoment {
            perfectMoment = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            perfectFlashTask?.cancel()
            perfectFlashTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 900_000_000)
                await MainActor.run { self?.perfectMoment = false }
            }
        }
    }

    // MARK: - Capture

    func shutterPressed() {
        if timerSeconds == 0 {
            capturePhoto()
        } else {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timerSeconds) * 1_000_000_000)
                capturePhoto()
            }
        }
    }

    private func capturePhoto() {
        cameraService.capturePhoto { [weak self] image in
            self?.lastCapturedImage = image
        }
    }

    // MARK: - Context & generation

    private func currentContext() -> PoseContext {
        var ctx = PoseContext.from(detection: detection)
        ctx.colorTemperature = cameraService.currentWhiteBalanceKelvin
        return ctx
    }

    /// Called whenever detection updates — decides whether to regenerate.
    private func maybeRegenerate() {
        let ctx = currentContext()
        let materialChange: Bool = {
            guard let last = lastContext else { return true }
            return ctx.majorDelta(from: last)
        }()
        if materialChange || aiEngine.shouldRegenerate(for: ctx) {
            scheduleGeneration(force: false)
        }
    }

    private func scheduleGeneration(force: Bool) {
        let ctx = currentContext()
        generationTask?.cancel()
        lastContext = ctx
        isGenerating = true

        generationTask = Task { [weak self] in
            guard let self else { return }

            // Try the AI engine first.
            var aiResult: [GeneratedPose]? = nil
            if self.aiEngine.isAvailable {
                aiResult = try? await self.aiEngine.generatePoses(from: ctx, limit: 5, force: force)
            }
            if Task.isCancelled { return }

            let result: [GeneratedPose]
            if let aiResult, !aiResult.isEmpty {
                result = aiResult
            } else {
                result = PoseFallbackEngine.poses(for: ctx, limit: 5)
            }

            await MainActor.run {
                self.isFallbackMode = !self.aiEngine.isAvailable || (aiResult?.isEmpty ?? true)
                self.isGenerating = false
                self.applyNewBatch(result)
            }
        }
    }

    private func applyNewBatch(_ fresh: [GeneratedPose]) {
        guard suggestedPoses.map(\.id) != fresh.map(\.id) else { return }
        suggestedPoses = fresh
        if !fresh.contains(where: { $0.id == selectedPoseID }) {
            selectedPoseID = fresh.first?.id
        }
    }
}

// MARK: - VisionServiceDelegate

extension CameraViewModel: VisionServiceDelegate {
    nonisolated func visionService(_ service: VisionService, didUpdate frame: VisionFrame) {
        Task { @MainActor in
            self.bodyPose = frame.bodyPose
            self.subjectRect = frame.primaryPersonRect

            var result = self.detection
            result.personCount = frame.personCount
            result.currentPosture = frame.posture
            result.detectedScene = self.latestScene

            let reading = LightAnalyzerService.Reading(
                iso: self.cameraService.currentISO,
                kelvin: self.cameraService.currentWhiteBalanceKelvin,
                exposureSeconds: CMTimeGetSeconds(self.cameraService.currentExposureDuration)
            )
            result.detectedLighting = self.lightAnalyzer.classify(
                reading: reading,
                location: self.latestLocation,
                scene: self.latestScene
            )
            result.timeOfDay = Self.timeOfDayLabel(for: Date())

            if let rect = frame.primaryPersonRect {
                let area = rect.width * rect.height
                if area > 0.45 { result.framingQuality = .excellent }
                else if area > 0.20 { result.framingQuality = .good }
                else { result.framingQuality = .poor }
            } else {
                result.framingQuality = .unknown
            }

            if let pose = frame.bodyPose {
                let confidence = Double(pose.joints.values.map { $0.confidence }.reduce(0, +)) /
                    Double(max(pose.joints.count, 1))
                result.poseMatchConfidence = min(1.0, confidence)
            } else {
                result.poseMatchConfidence = 0
            }

            self.detection = result
            self.maybeRegenerate()
        }
    }

    private static func timeOfDayLabel(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<8:   return "Sunrise"
        case 8..<11:  return "Morning"
        case 11..<14: return "Midday"
        case 14..<17: return "Afternoon"
        case 17..<20: return "Golden Hour"
        case 20..<22: return "Dusk"
        default:      return "Night"
        }
    }
}

private final class FrameReceiverBridge: NSObject, CameraFrameReceiver {
    var onFrame: ((CMSampleBuffer) -> Void)?
    func camera(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        onFrame?(sampleBuffer)
    }
}
