import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generates portrait poses on-device using Apple's Foundation Models (iOS 26+,
/// iPhone 15 Pro+). Every pose the user sees in the AI path comes from here.
/// Returns `nil` from `generatePoses` when the device can't run the model — the
/// caller should then dispatch to `PoseFallbackEngine`.
///
/// Debounce: calls within `minInterval` seconds return the cached batch unless
/// the context has materially changed (person count, scene, ±500K lighting).
@MainActor
final class PoseAIEngine {
    static let shared = PoseAIEngine()

    private(set) var lastContext: PoseContext?
    private(set) var lastPoses: [GeneratedPose] = []
    private var lastGeneratedAt: Date?
    private var inflight: Task<[GeneratedPose]?, Error>?

    /// Minimum spacing between successive LLM calls for the same context.
    let minInterval: TimeInterval = 3.0
    /// After this much time we force a regeneration even if nothing changed.
    let maxStaleness: TimeInterval = 18.0

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    /// Runs the model and returns a freshly generated batch. Returns `nil`
    /// when Foundation Models isn't available on the current device — caller
    /// dispatches to the fallback engine. Throws on transient model errors.
    func generatePoses(from context: PoseContext,
                       limit: Int = 5,
                       force: Bool = false) async throws -> [GeneratedPose]? {
        guard isAvailable else { return nil }

        if !force, let cached = cachedIfFresh(for: context) {
            return cached
        }

        if let inflight {
            return try await inflight.value
        }

        let task = Task<[GeneratedPose]?, Error> { [weak self] in
            guard let self else { return nil }
            let result = try await Self.run(context: context, limit: limit)
            await MainActor.run {
                self.lastPoses = result
                self.lastContext = context
                self.lastGeneratedAt = Date()
                self.inflight = nil
            }
            return result
        }
        inflight = task
        return try await task.value
    }

    /// Clears the cache — force next call to regenerate regardless of debounce.
    func invalidate() {
        lastGeneratedAt = nil
        inflight?.cancel()
        inflight = nil
    }

    /// Returns whether the caller *should* regenerate given a new context.
    /// Used by CameraViewModel to decide when to bust the 15-20s timer.
    func shouldRegenerate(for context: PoseContext, now: Date = Date()) -> Bool {
        guard let last = lastGeneratedAt else { return true }
        let elapsed = now.timeIntervalSince(last)
        if elapsed >= maxStaleness { return true }
        if let lastContext, context.majorDelta(from: lastContext) { return true }
        return false
    }

    // MARK: - Cache

    private func cachedIfFresh(for context: PoseContext) -> [GeneratedPose]? {
        guard
            let last = lastGeneratedAt,
            Date().timeIntervalSince(last) < minInterval,
            !lastPoses.isEmpty
        else { return nil }
        if let lastContext, context.majorDelta(from: lastContext) { return nil }
        return lastPoses
    }

    // MARK: - Model invocation

    private static func run(context: PoseContext, limit: Int) async throws -> [GeneratedPose] {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return try await FoundationModelsDriver.generate(context: context, limit: limit)
        }
        #endif
        return []
    }
}

#if canImport(FoundationModels)
@available(iOS 26, *)
private enum FoundationModelsDriver {

    // MARK: - @Generable schema

    @Generable
    struct AIKeypoint {
        @Guide(description: "X coordinate, normalized 0.0 (left edge) to 1.0 (right edge).")
        var x: Double
        @Guide(description: "Y coordinate, normalized 0.0 (top edge) to 1.0 (bottom edge).")
        var y: Double
    }

    @Generable
    struct AIPose {
        @Guide(description: "Short slug id, e.g. 'soft-lean-01'.")
        var id: String
        @Guide(description: "Poetic, concise pose name (3-5 words).")
        var name: String
        @Guide(description: "One-sentence description of the pose and its mood.")
        var description: String
        @Guide(description: "One of: portrait, streetStyle, couple, editorial, wedding, group, sitting, action, fullBody")
        var category: String
        @Guide(description: "One of: easy, medium, hard")
        var difficulty: String
        @Guide(description: "2-4 concise directing tips. Each tip 'Title — short body'.")
        var tips: [String]
        @Guide(description: "Match score 0.0-1.0 for how well this pose fits the current scene.")
        var matchScore: Double
        var head: AIKeypoint
        var neck: AIKeypoint
        var leftShoulder: AIKeypoint
        var rightShoulder: AIKeypoint
        var leftElbow: AIKeypoint
        var rightElbow: AIKeypoint
        var leftWrist: AIKeypoint
        var rightWrist: AIKeypoint
        var leftHip: AIKeypoint
        var rightHip: AIKeypoint
        var leftKnee: AIKeypoint
        var rightKnee: AIKeypoint
        var leftAnkle: AIKeypoint
        var rightAnkle: AIKeypoint
    }

    @Generable
    struct AIPoseBatch {
        @Guide(description: "Array of portrait poses tailored to the scene, best match first.")
        var poses: [AIPose]
    }

    // MARK: - Entrypoint

    static func generate(context: PoseContext, limit: Int) async throws -> [GeneratedPose] {
        let isTurkish = Locale.current.language.languageCode?.identifier == "tr"
        let instructions: String
        if isTurkish {
            instructions = """
            Sen FotoPose adlı bir uygulama için dünya çapında bir portre fotoğrafçılığı poz yönetmenisin. \
            Verilen sahne analizine göre özne(ler) için taze, editöryal, güzel gösteren pozlar üret. \
            Poz adları, açıklamaları ve ipuçları Türkçe olmalı — doğal, kısa ve yönlendirici bir dille yaz. \
            Koordinatları dikey 0.0-1.0 kare içinde ver; (0,0) sol üst, (1,1) sağ alt köşedir. \
            Tüm iskeleti karenin içinde tut ve yatayda yaklaşık ortala. \
            Baş y≈0.08-0.18 civarında; ayaklar tam boy ayakta pozlarda y≈0.90-0.98 civarında olsun. \
            Oturma/çömelme pozlarında dikey yayılımı buna göre daralt. \
            Eklem zincirleri anatomik olarak tutarlı olsun (omuzlar kalçalardan geniş, dizler kalçaların altında, ayak bilekleri dizlerin altında).
            """
        } else {
            instructions = """
            You are a world-class portrait photography director for an app called FotoPose. \
            Given a live scene description, invent fresh, editorial, flattering poses for the subject(s). \
            Pose names, descriptions and tips must be in English — write naturally and directively. \
            Output coordinates in a portrait 0.0-1.0 frame with (0,0) at the top-left and (1,1) at the bottom-right. \
            Keep the full skeleton inside the frame, roughly centered horizontally. \
            The head should sit near y≈0.08-0.18; feet near y≈0.90-0.98 for full-body standing poses. \
            For sitting/crouching poses compress vertical spread accordingly. \
            Keep joint chains anatomically plausible (shoulders wider than hips, knees below hips, ankles below knees).
            """
        }

        let prompt = """
        Scene:
          people=\(context.personCount)
          posture=\(context.currentPosture)
          gender=\(context.estimatedGender)
          body_type=\(context.estimatedBodyType)
          scene=\(context.sceneType)
          lighting=\(context.lightingCondition)
          time=\(context.timeOfDay)
          golden_hour=\(context.isGoldenHour)
        \(context.userQuery.isEmpty ? "" : "  user_query=\(context.userQuery)\n")\
        \(context.categoryHint.isEmpty ? "" : "  category_hint=\(context.categoryHint)\n")\

        Generate \(limit) distinct poses tailored to this scene. Vary the mood and energy. \
        Each pose must have all 14 keypoints filled with plausible normalized coordinates.
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt, generating: AIPoseBatch.self)
        return response.content.poses.map { Self.convert($0) }
    }

    // MARK: - Conversion

    private static func convert(_ ai: AIPose) -> GeneratedPose {
        let kp = PoseKeypoints(
            head:          NormalizedPoint(x: clamp(ai.head.x), y: clamp(ai.head.y)),
            neck:          NormalizedPoint(x: clamp(ai.neck.x), y: clamp(ai.neck.y)),
            leftShoulder:  NormalizedPoint(x: clamp(ai.leftShoulder.x), y: clamp(ai.leftShoulder.y)),
            rightShoulder: NormalizedPoint(x: clamp(ai.rightShoulder.x), y: clamp(ai.rightShoulder.y)),
            leftElbow:     NormalizedPoint(x: clamp(ai.leftElbow.x), y: clamp(ai.leftElbow.y)),
            rightElbow:    NormalizedPoint(x: clamp(ai.rightElbow.x), y: clamp(ai.rightElbow.y)),
            leftWrist:     NormalizedPoint(x: clamp(ai.leftWrist.x), y: clamp(ai.leftWrist.y)),
            rightWrist:    NormalizedPoint(x: clamp(ai.rightWrist.x), y: clamp(ai.rightWrist.y)),
            leftHip:       NormalizedPoint(x: clamp(ai.leftHip.x), y: clamp(ai.leftHip.y)),
            rightHip:      NormalizedPoint(x: clamp(ai.rightHip.x), y: clamp(ai.rightHip.y)),
            leftKnee:      NormalizedPoint(x: clamp(ai.leftKnee.x), y: clamp(ai.leftKnee.y)),
            rightKnee:     NormalizedPoint(x: clamp(ai.rightKnee.x), y: clamp(ai.rightKnee.y)),
            leftAnkle:     NormalizedPoint(x: clamp(ai.leftAnkle.x), y: clamp(ai.leftAnkle.y)),
            rightAnkle:    NormalizedPoint(x: clamp(ai.rightAnkle.x), y: clamp(ai.rightAnkle.y))
        )
        return GeneratedPose(
            id: ai.id,
            name: ai.name,
            description: ai.description,
            category: ai.category,
            difficulty: ai.difficulty,
            tips: ai.tips,
            bodyKeypoints: kp,
            matchScore: max(0, min(1, ai.matchScore)),
            isFallback: false
        )
    }

    private static func clamp(_ v: Double) -> Double { max(0, min(1, v)) }
}
#endif
