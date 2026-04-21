import Foundation

/// Activates automatically on devices without Foundation Models (iOS <26 or
/// non-supported hardware). Returns hand-authored `GeneratedPose` templates
/// filtered and ranked against the live context, so users still get useful
/// suggestions — with an "upgrade" banner surfaced by the UI.
struct PoseFallbackEngine {

    /// UI banner copy — shown when a fallback result is served.
    static var upgradeBanner: String {
        "Upgrade to iPhone 15 Pro for AI-powered suggestions".localized
    }

    /// Returns up to `limit` poses most relevant to the context, sorted by
    /// match score. Always returns at least one pose.
    static func poses(for context: PoseContext, limit: Int = 5) -> [GeneratedPose] {
        let scored = templates.map { template -> (GeneratedPose, Double) in
            let score = rank(template, context: context)
            var pose = template
            pose.matchScore = score
            return (pose, score)
        }
        let ordered = scored
            .sorted { lhs, rhs in lhs.1 > rhs.1 }
            .prefix(limit)
            .map(\.0)
        if ordered.isEmpty {
            return Array(templates.prefix(limit))
        }
        return Array(ordered)
    }

    /// Everything (no context filter) — used by Library's default "Perfect for Now"
    /// strip when no detection is active yet.
    static var all: [GeneratedPose] { templates }

    /// Subset for a given category.
    static func poses(in category: PoseCategory) -> [GeneratedPose] {
        templates.filter { $0.category == category.rawValue }
    }

    /// Subset for free-form search — matches against name, description, tips.
    static func search(_ query: String) -> [GeneratedPose] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return templates }
        return templates.filter { pose in
            if pose.name.lowercased().contains(q) { return true }
            if pose.description.lowercased().contains(q) { return true }
            if pose.tips.contains(where: { $0.lowercased().contains(q) }) { return true }
            if pose.category.lowercased().contains(q) { return true }
            return false
        }
    }

    // MARK: - Scoring

    private static func rank(_ pose: GeneratedPose, context: PoseContext) -> Double {
        var score = 0.5

        if pose.personCount == context.personCount {
            score += 0.25
        } else if abs(pose.personCount - context.personCount) == 1 {
            score += 0.05
        } else {
            score -= 0.2
        }

        if let lighting = Lighting(rawValue: context.lightingCondition),
           pose.suitableLighting.contains(lighting) || pose.suitableLighting.contains(.any) {
            score += 0.1
            if pose.suitableLighting.first == lighting { score += 0.05 }
        }
        if let scene = Scene(rawValue: context.sceneType),
           pose.suitableScene.contains(scene) || pose.suitableScene.contains(.any) {
            score += 0.1
        }
        if !context.categoryHint.isEmpty, pose.category == context.categoryHint {
            score += 0.2
        }
        return max(0, min(1, score))
    }

    // MARK: - Builders

    private static func pose(
        _ id: String,
        name: String,
        description: String,
        category: PoseCategory,
        difficulty: Difficulty,
        tips: [String],
        keypoints: PoseKeypoints,
        personCount: Int = 1,
        lighting: [Lighting] = [.any],
        scene: [Scene] = [.any],
        isPro: Bool = false
    ) -> GeneratedPose {
        GeneratedPose(
            id: id,
            name: name,
            description: description,
            category: category.rawValue,
            difficulty: difficulty.rawValue,
            tips: tips,
            bodyKeypoints: keypoints,
            matchScore: 0.6,
            isFallback: true,
            personCount: personCount,
            suitableLighting: lighting,
            suitableScene: scene,
            isPro: isPro
        )
    }

    /// Helper to build a skeleton from a compact tuple array — saves ~30 lines per template.
    private static func skel(
        _ head: (Double, Double),
        _ neck: (Double, Double),
        _ lShoulder: (Double, Double), _ rShoulder: (Double, Double),
        _ lElbow: (Double, Double), _ rElbow: (Double, Double),
        _ lWrist: (Double, Double), _ rWrist: (Double, Double),
        _ lHip: (Double, Double), _ rHip: (Double, Double),
        _ lKnee: (Double, Double), _ rKnee: (Double, Double),
        _ lAnkle: (Double, Double), _ rAnkle: (Double, Double)
    ) -> PoseKeypoints {
        PoseKeypoints(
            head:          NormalizedPoint(x: head.0, y: head.1),
            neck:          NormalizedPoint(x: neck.0, y: neck.1),
            leftShoulder:  NormalizedPoint(x: lShoulder.0, y: lShoulder.1),
            rightShoulder: NormalizedPoint(x: rShoulder.0, y: rShoulder.1),
            leftElbow:     NormalizedPoint(x: lElbow.0, y: lElbow.1),
            rightElbow:    NormalizedPoint(x: rElbow.0, y: rElbow.1),
            leftWrist:     NormalizedPoint(x: lWrist.0, y: lWrist.1),
            rightWrist:    NormalizedPoint(x: rWrist.0, y: rWrist.1),
            leftHip:       NormalizedPoint(x: lHip.0, y: lHip.1),
            rightHip:      NormalizedPoint(x: rHip.0, y: rHip.1),
            leftKnee:      NormalizedPoint(x: lKnee.0, y: lKnee.1),
            rightKnee:     NormalizedPoint(x: rKnee.0, y: rKnee.1),
            leftAnkle:     NormalizedPoint(x: lAnkle.0, y: lAnkle.1),
            rightAnkle:    NormalizedPoint(x: rAnkle.0, y: rAnkle.1)
        )
    }

    // MARK: - Templates (~30)

    private static let templates: [GeneratedPose] = [

        // --- Solo — Portrait / Editorial ---
        pose("fb-soft-gaze",
             name: "Soft Gaze Over Shoulder",
             description: "Head turned slightly back, chin tucked, eyes meeting the lens.",
             category: .portrait, difficulty: .easy,
             tips: [
                 "Posture — Relax shoulders, lengthen the neck.",
                 "Eyes — Look just past the lens for a softer gaze.",
                 "Light — Let the light catch one side of the face."
             ],
             keypoints: skel(
                 (0.48, 0.12), (0.50, 0.20),
                 (0.40, 0.26), (0.60, 0.24),
                 (0.36, 0.40), (0.66, 0.40),
                 (0.38, 0.54), (0.68, 0.54),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.softLight, .goldenHour, .any], scene: [.any]),

        pose("fb-editorial-hand-to-hair",
             name: "Hand Sweeping Through Hair",
             description: "Dynamic editorial pose with one hand lifted to the hair.",
             category: .editorial, difficulty: .medium,
             tips: [
                 "Motion — Sweep the hand, don't hold still.",
                 "Elbow — Keep it slightly bent, never locked.",
                 "Expression — Part the lips for a natural feel."
             ],
             keypoints: skel(
                 (0.50, 0.12), (0.50, 0.20),
                 (0.40, 0.24), (0.60, 0.24),
                 (0.34, 0.32), (0.66, 0.38),
                 (0.40, 0.18), (0.70, 0.52),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.softLight, .studio], scene: [.studio, .indoor]),

        pose("fb-classic-leading",
             name: "Classic Leading Lady",
             description: "Slight contrapposto with weight on back leg, chin down.",
             category: .portrait, difficulty: .easy,
             tips: [
                 "Weight — Shift onto the back foot.",
                 "Hips — Angle 15° away from camera.",
                 "Chin — Drop slightly, lengthen the jaw."
             ],
             keypoints: skel(
                 (0.50, 0.11), (0.51, 0.19),
                 (0.42, 0.23), (0.60, 0.23),
                 (0.38, 0.38), (0.64, 0.38),
                 (0.36, 0.52), (0.66, 0.52),
                 (0.45, 0.57), (0.56, 0.57),
                 (0.44, 0.77), (0.57, 0.77),
                 (0.43, 0.96), (0.58, 0.96)
             ),
             lighting: [.any], scene: [.any]),

        pose("fb-confident-stride",
             name: "Confident Stride",
             description: "Mid-stride, arms swinging, eyes ahead — street-style energy.",
             category: .streetStyle, difficulty: .medium,
             tips: [
                 "Stride — Take a real step, not a pose.",
                 "Arms — Let them swing naturally.",
                 "Gaze — Look past the photographer, not at them."
             ],
             keypoints: skel(
                 (0.50, 0.11), (0.51, 0.19),
                 (0.41, 0.23), (0.60, 0.23),
                 (0.36, 0.35), (0.66, 0.36),
                 (0.40, 0.50), (0.70, 0.48),
                 (0.44, 0.57), (0.56, 0.57),
                 (0.40, 0.77), (0.60, 0.73),
                 (0.36, 0.96), (0.64, 0.90)
             ),
             lighting: [.goldenHour, .any], scene: [.city, .outdoor, .park]),

        pose("fb-lean-against-wall",
             name: "Lean Against Wall",
             description: "Shoulder blades on wall, one knee bent and raised toward the camera.",
             category: .streetStyle, difficulty: .easy,
             tips: [
                 "Contact — Touch the wall with shoulders and hips only.",
                 "Leg — Raise the knee closest to the camera.",
                 "Hands — Rest them in pockets or at the hips."
             ],
             keypoints: skel(
                 (0.52, 0.13), (0.51, 0.21),
                 (0.42, 0.25), (0.60, 0.24),
                 (0.38, 0.38), (0.66, 0.36),
                 (0.36, 0.52), (0.68, 0.50),
                 (0.45, 0.58), (0.55, 0.58),
                 (0.38, 0.72), (0.56, 0.78),
                 (0.42, 0.85), (0.57, 0.96)
             ),
             lighting: [.any], scene: [.city, .indoor, .studio]),

        pose("fb-sit-stairs",
             name: "Seated on Stairs",
             description: "Sitting low with forearms on knees, shoulders forward.",
             category: .sitting, difficulty: .easy,
             tips: [
                 "Frame — Keep knees below shoulder height.",
                 "Hands — Clasp loosely or rest one on knee.",
                 "Angle — Turn hips slightly away from camera."
             ],
             keypoints: skel(
                 (0.50, 0.18), (0.50, 0.26),
                 (0.40, 0.30), (0.60, 0.30),
                 (0.36, 0.46), (0.64, 0.46),
                 (0.42, 0.58), (0.58, 0.58),
                 (0.42, 0.60), (0.58, 0.60),
                 (0.34, 0.72), (0.66, 0.72),
                 (0.38, 0.92), (0.62, 0.92)
             ),
             lighting: [.softLight, .goldenHour], scene: [.city, .outdoor]),

        pose("fb-candid-laugh",
             name: "Candid Laugh",
             description: "Head tipped back slightly, hand rising toward face.",
             category: .portrait, difficulty: .easy,
             tips: [
                 "Trigger — Share a joke before shooting.",
                 "Hand — Let it float, don't pin it to the face.",
                 "Eyes — Closed briefly is okay — catch the moment."
             ],
             keypoints: skel(
                 (0.52, 0.10), (0.50, 0.19),
                 (0.40, 0.23), (0.60, 0.23),
                 (0.36, 0.34), (0.66, 0.38),
                 (0.46, 0.18), (0.72, 0.50),
                 (0.44, 0.57), (0.56, 0.57),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.any], scene: [.any]),

        pose("fb-golden-flare",
             name: "Golden Hour Halo",
             description: "Backlit profile, head turned three-quarters toward the sun.",
             category: .portrait, difficulty: .medium,
             tips: [
                 "Position — Face 45° from the sun.",
                 "Hair — Let the light rim your outline.",
                 "Expose — For the face, not the sky."
             ],
             keypoints: skel(
                 (0.46, 0.13), (0.50, 0.21),
                 (0.40, 0.25), (0.60, 0.25),
                 (0.36, 0.40), (0.64, 0.40),
                 (0.38, 0.54), (0.66, 0.54),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.goldenHour, .blueHour], scene: [.outdoor, .beach, .park]),

        pose("fb-full-body-power",
             name: "Full Body Power Stance",
             description: "Feet shoulder-width apart, chin up, hands on hips.",
             category: .fullBody, difficulty: .easy,
             tips: [
                 "Feet — Plant them firmly, shoulder-width.",
                 "Hands — On the hips, not the belt.",
                 "Chin — Up and out, not tilted back."
             ],
             keypoints: skel(
                 (0.50, 0.10), (0.50, 0.18),
                 (0.40, 0.22), (0.60, 0.22),
                 (0.34, 0.36), (0.66, 0.36),
                 (0.38, 0.52), (0.62, 0.52),
                 (0.42, 0.56), (0.58, 0.56),
                 (0.40, 0.76), (0.60, 0.76),
                 (0.38, 0.96), (0.62, 0.96)
             ),
             lighting: [.any], scene: [.any]),

        pose("fb-action-spin",
             name: "Twirl and Glance",
             description: "Mid-twirl with hair trailing, hand holding the skirt or jacket.",
             category: .action, difficulty: .hard,
             tips: [
                 "Motion — Commit to the spin, don't fake it.",
                 "Shutter — 1/500s minimum to freeze motion.",
                 "Glance — Make eye contact during the turn."
             ],
             keypoints: skel(
                 (0.52, 0.12), (0.50, 0.20),
                 (0.38, 0.25), (0.62, 0.23),
                 (0.30, 0.38), (0.70, 0.34),
                 (0.28, 0.54), (0.76, 0.46),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.40, 0.78), (0.60, 0.76),
                 (0.36, 0.96), (0.64, 0.94)
             ),
             isPro: true,
             lighting: [.goldenHour, .softLight], scene: [.outdoor, .park, .beach]),

        pose("fb-crossed-arms",
             name: "Crossed Arms, Soft Smile",
             description: "Arms folded gently, weight on back leg.",
             category: .portrait, difficulty: .easy,
             tips: [
                 "Arms — Fold, don't brace. Keep it loose.",
                 "Smile — Start from the eyes.",
                 "Shoulder — Drop the front one slightly."
             ],
             keypoints: skel(
                 (0.50, 0.12), (0.50, 0.20),
                 (0.40, 0.24), (0.60, 0.24),
                 (0.36, 0.36), (0.64, 0.36),
                 (0.46, 0.44), (0.54, 0.44),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.any], scene: [.any]),

        pose("fb-hand-in-pocket",
             name: "One Hand in Pocket",
             description: "Relaxed stance with one hand tucked in pocket, other at side.",
             category: .streetStyle, difficulty: .easy,
             tips: [
                 "Pocket — Thumb out, four fingers in.",
                 "Shoulder — Drop the pocketed-hand shoulder.",
                 "Gaze — Look slightly off-camera for cool."
             ],
             keypoints: skel(
                 (0.50, 0.11), (0.50, 0.19),
                 (0.40, 0.23), (0.60, 0.23),
                 (0.36, 0.38), (0.64, 0.36),
                 (0.38, 0.54), (0.58, 0.52),
                 (0.44, 0.56), (0.56, 0.56),
                 (0.44, 0.77), (0.56, 0.77),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.any], scene: [.city, .outdoor, .indoor]),

        pose("fb-profile-strong",
             name: "Profile — Chin Up",
             description: "Straight profile, chin lifted, shoulders square to body direction.",
             category: .editorial, difficulty: .medium,
             tips: [
                 "Profile — Align nose with the edge of the frame.",
                 "Chin — Lift until the jaw traces a clean line.",
                 "Shoulder — Push the far one back to slim the silhouette."
             ],
             keypoints: skel(
                 (0.44, 0.12), (0.50, 0.20),
                 (0.46, 0.24), (0.58, 0.24),
                 (0.44, 0.38), (0.60, 0.38),
                 (0.42, 0.52), (0.62, 0.52),
                 (0.48, 0.58), (0.56, 0.58),
                 (0.48, 0.78), (0.56, 0.78),
                 (0.48, 0.96), (0.56, 0.96)
             ),
             isPro: true,
             lighting: [.studio, .softLight], scene: [.studio, .indoor]),

        pose("fb-kneel-forward",
             name: "Kneel and Lean In",
             description: "One knee down, elbow on the other knee, chin resting on hand.",
             category: .sitting, difficulty: .medium,
             tips: [
                 "Knee — Plant only one, keep the other at 90°.",
                 "Elbow — Rest it on the standing knee.",
                 "Chin — Just brush the knuckles, don't smash."
             ],
             keypoints: skel(
                 (0.48, 0.20), (0.50, 0.28),
                 (0.40, 0.32), (0.60, 0.32),
                 (0.36, 0.46), (0.62, 0.46),
                 (0.40, 0.50), (0.54, 0.54),
                 (0.44, 0.62), (0.56, 0.62),
                 (0.38, 0.78), (0.58, 0.82),
                 (0.42, 0.94), (0.62, 0.92)
             ),
             lighting: [.any], scene: [.outdoor, .park, .indoor]),

        pose("fb-hand-behind-neck",
             name: "Hand Behind Neck",
             description: "One hand cradling the nape, elbow raised, weight shifted.",
             category: .editorial, difficulty: .medium,
             tips: [
                 "Elbow — Raise it above the shoulder for drama.",
                 "Fingers — Splay them in the hair, don't ball up.",
                 "Body — Twist at the waist, not the hips."
             ],
             keypoints: skel(
                 (0.48, 0.12), (0.50, 0.20),
                 (0.40, 0.24), (0.60, 0.24),
                 (0.38, 0.36), (0.66, 0.16),
                 (0.42, 0.50), (0.56, 0.22),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.42, 0.78), (0.58, 0.78),
                 (0.42, 0.96), (0.58, 0.96)
             ),
             lighting: [.studio, .softLight], scene: [.studio, .indoor]),

        pose("fb-window-light",
             name: "Window-Light Moment",
             description: "Facing a window, light falling on one side of the face.",
             category: .portrait, difficulty: .easy,
             tips: [
                 "Angle — 90° to the window for Rembrandt light.",
                 "Stillness — Stay in one spot for even exposure.",
                 "Shadow — Don't fight it, let it shape the face."
             ],
             keypoints: skel(
                 (0.50, 0.13), (0.50, 0.21),
                 (0.40, 0.25), (0.60, 0.25),
                 (0.36, 0.40), (0.64, 0.40),
                 (0.38, 0.54), (0.62, 0.54),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.softLight], scene: [.indoor]),

        // --- Couples ---
        pose("fb-couple-forehead",
             name: "Forehead-to-Forehead",
             description: "Couple touching foreheads, eyes closed, hands gently held.",
             category: .couple, difficulty: .easy,
             tips: [
                 "Space — No gap between foreheads.",
                 "Hands — Interlock, don't grip.",
                 "Smile — Soft, closed-mouth."
             ],
             keypoints: skel(
                 (0.40, 0.14), (0.42, 0.22),
                 (0.32, 0.26), (0.52, 0.26),
                 (0.28, 0.40), (0.56, 0.40),
                 (0.30, 0.54), (0.58, 0.54),
                 (0.36, 0.58), (0.48, 0.58),
                 (0.36, 0.78), (0.48, 0.78),
                 (0.36, 0.96), (0.48, 0.96)
             ),
             personCount: 2, lighting: [.goldenHour, .softLight], scene: [.any]),

        pose("fb-couple-walking",
             name: "Walking Hand-in-Hand",
             description: "Both walking toward camera, holding hands, laughing.",
             category: .couple, difficulty: .easy,
             tips: [
                 "Stride — Sync your pace.",
                 "Hands — Swing them, don't pin.",
                 "Gaze — Look at each other on odd steps."
             ],
             keypoints: skel(
                 (0.35, 0.12), (0.38, 0.20),
                 (0.28, 0.24), (0.48, 0.24),
                 (0.24, 0.38), (0.52, 0.38),
                 (0.28, 0.52), (0.54, 0.52),
                 (0.34, 0.56), (0.46, 0.56),
                 (0.30, 0.76), (0.50, 0.76),
                 (0.28, 0.96), (0.52, 0.96)
             ),
             personCount: 2, lighting: [.goldenHour, .any], scene: [.outdoor, .park, .beach, .city]),

        pose("fb-couple-back-hug",
             name: "Back Hug at Sunset",
             description: "One partner hugging from behind, both gazing into the distance.",
             category: .couple, difficulty: .medium,
             tips: [
                 "Hug — Arms wrapped around the waist.",
                 "Chin — Front partner's chin on shoulder.",
                 "Eyes — Both looking the same direction."
             ],
             keypoints: skel(
                 (0.50, 0.12), (0.50, 0.20),
                 (0.38, 0.24), (0.62, 0.24),
                 (0.30, 0.36), (0.70, 0.36),
                 (0.34, 0.48), (0.66, 0.48),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             personCount: 2, lighting: [.goldenHour, .blueHour], scene: [.beach, .outdoor]),

        pose("fb-couple-seated-close",
             name: "Seated, Close & Candid",
             description: "Sitting side by side, one leg crossed over the other.",
             category: .couple, difficulty: .easy,
             tips: [
                 "Proximity — Touch shoulders, hips, knees.",
                 "Cross — One partner crosses legs toward the other.",
                 "Hands — One hand on the other's knee."
             ],
             keypoints: skel(
                 (0.44, 0.18), (0.46, 0.26),
                 (0.36, 0.30), (0.56, 0.30),
                 (0.30, 0.42), (0.62, 0.42),
                 (0.30, 0.54), (0.62, 0.54),
                 (0.40, 0.60), (0.52, 0.60),
                 (0.32, 0.76), (0.60, 0.76),
                 (0.30, 0.92), (0.64, 0.92)
             ),
             personCount: 2, lighting: [.softLight, .any], scene: [.outdoor, .indoor, .park]),

        // --- Wedding ---
        pose("fb-wedding-dip",
             name: "The Dip",
             description: "One partner dipping the other low, noses almost touching.",
             category: .wedding, difficulty: .hard,
             tips: [
                 "Support — Full arm under the back.",
                 "Angle — Dip 30°, not more.",
                 "Foot — Front foot stays planted."
             ],
             keypoints: skel(
                 (0.30, 0.20), (0.36, 0.28),
                 (0.28, 0.30), (0.48, 0.26),
                 (0.24, 0.42), (0.52, 0.36),
                 (0.22, 0.54), (0.56, 0.46),
                 (0.36, 0.58), (0.50, 0.56),
                 (0.34, 0.76), (0.54, 0.74),
                 (0.34, 0.92), (0.58, 0.92)
             ),
             isPro: true, personCount: 2,
             lighting: [.goldenHour, .softLight], scene: [.outdoor, .indoor]),

        pose("fb-wedding-veil",
             name: "Veil Floating Away",
             description: "Bride facing away, veil caught in motion, slight over-shoulder glance.",
             category: .wedding, difficulty: .medium,
             tips: [
                 "Timing — Fire the frame as the veil peaks.",
                 "Glance — Look over the shoulder just a beat.",
                 "Shutter — 1/800s to freeze the fabric."
             ],
             keypoints: skel(
                 (0.48, 0.14), (0.50, 0.22),
                 (0.40, 0.26), (0.60, 0.26),
                 (0.36, 0.40), (0.64, 0.40),
                 (0.38, 0.54), (0.62, 0.54),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             isPro: true,
             lighting: [.goldenHour], scene: [.outdoor, .beach]),

        // --- Group ---
        pose("fb-group-trio-step",
             name: "Trio — Stepped Heights",
             description: "Three subjects at descending heights — tallest back, shortest front.",
             category: .group, difficulty: .medium,
             tips: [
                 "Height — Stagger in three tiers.",
                 "Distance — Everyone within arm's reach.",
                 "Eye line — All subjects level, not tilted up."
             ],
             keypoints: skel(
                 (0.50, 0.10), (0.50, 0.18),
                 (0.38, 0.22), (0.62, 0.22),
                 (0.32, 0.34), (0.68, 0.34),
                 (0.30, 0.48), (0.70, 0.48),
                 (0.42, 0.56), (0.58, 0.56),
                 (0.42, 0.76), (0.58, 0.76),
                 (0.42, 0.96), (0.58, 0.96)
             ),
             personCount: 3, lighting: [.any], scene: [.any]),

        pose("fb-group-circle-laugh",
             name: "Circle — Mid-Laugh",
             description: "Group forming a loose circle, looking at each other laughing.",
             category: .group, difficulty: .easy,
             tips: [
                 "Shape — Loose circle, not a tight ring.",
                 "Gaze — Don't all look at the camera.",
                 "Spark — Share a real joke first."
             ],
             keypoints: skel(
                 (0.50, 0.15), (0.50, 0.23),
                 (0.34, 0.27), (0.66, 0.27),
                 (0.28, 0.40), (0.72, 0.40),
                 (0.32, 0.54), (0.68, 0.54),
                 (0.42, 0.58), (0.58, 0.58),
                 (0.42, 0.78), (0.58, 0.78),
                 (0.42, 0.96), (0.58, 0.96)
             ),
             personCount: 3, lighting: [.any], scene: [.outdoor, .park, .city]),

        // --- Sitting ---
        pose("fb-sit-cross-legged",
             name: "Cross-Legged on Ground",
             description: "Sitting cross-legged, hands resting on knees, relaxed.",
             category: .sitting, difficulty: .easy,
             tips: [
                 "Back — Lengthen, don't slouch.",
                 "Hands — Rest palms up on the knees.",
                 "Shoulders — Roll back once before the frame."
             ],
             keypoints: skel(
                 (0.50, 0.22), (0.50, 0.30),
                 (0.40, 0.34), (0.60, 0.34),
                 (0.34, 0.48), (0.66, 0.48),
                 (0.38, 0.60), (0.62, 0.60),
                 (0.44, 0.64), (0.56, 0.64),
                 (0.34, 0.76), (0.66, 0.76),
                 (0.30, 0.84), (0.70, 0.84)
             ),
             lighting: [.any], scene: [.outdoor, .park, .indoor, .studio]),

        pose("fb-sit-chair-relaxed",
             name: "Chair, Leg Crossed",
             description: "Seated with one ankle over opposite knee, hand on chair arm.",
             category: .sitting, difficulty: .easy,
             tips: [
                 "Cross — Ankle on knee, not knee on knee.",
                 "Posture — Press lower back against the chair.",
                 "Angle — Turn the chair 15° from camera."
             ],
             keypoints: skel(
                 (0.50, 0.16), (0.50, 0.24),
                 (0.40, 0.28), (0.60, 0.28),
                 (0.32, 0.40), (0.64, 0.40),
                 (0.32, 0.50), (0.66, 0.50),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.36, 0.70), (0.60, 0.76),
                 (0.34, 0.86), (0.66, 0.90)
             ),
             lighting: [.softLight, .studio], scene: [.indoor, .studio]),

        // --- Street / Action ---
        pose("fb-jump-playful",
             name: "Playful Mid-Air Jump",
             description: "Full-body jump, knees tucked, arms flung wide.",
             category: .action, difficulty: .hard,
             tips: [
                 "Commit — Push hard off both feet.",
                 "Shutter — 1/1000s minimum.",
                 "Expression — Laugh, don't pose."
             ],
             keypoints: skel(
                 (0.50, 0.08), (0.50, 0.16),
                 (0.34, 0.20), (0.66, 0.20),
                 (0.26, 0.30), (0.74, 0.30),
                 (0.22, 0.40), (0.78, 0.40),
                 (0.44, 0.50), (0.56, 0.50),
                 (0.38, 0.60), (0.62, 0.60),
                 (0.36, 0.72), (0.64, 0.72)
             ),
             lighting: [.any], scene: [.outdoor, .park, .beach]),

        pose("fb-against-railing",
             name: "Leaning on Railing",
             description: "Elbows on a railing, shoulders relaxed, gaze outward.",
             category: .streetStyle, difficulty: .easy,
             tips: [
                 "Elbows — Rest, don't press.",
                 "Hip — Shift weight to one leg.",
                 "Gaze — Toward the horizon, not the lens."
             ],
             keypoints: skel(
                 (0.50, 0.18), (0.50, 0.26),
                 (0.40, 0.30), (0.60, 0.30),
                 (0.36, 0.40), (0.64, 0.40),
                 (0.40, 0.44), (0.60, 0.44),
                 (0.44, 0.56), (0.56, 0.56),
                 (0.44, 0.76), (0.56, 0.76),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             lighting: [.any], scene: [.city, .outdoor]),

        pose("fb-fullbody-3q",
             name: "Three-Quarter Angle",
             description: "Body turned 45° to camera, back foot carrying the weight.",
             category: .fullBody, difficulty: .easy,
             tips: [
                 "Angle — Exactly 45° — no more.",
                 "Weight — On the back foot.",
                 "Front foot — Pointed toward the lens."
             ],
             keypoints: skel(
                 (0.50, 0.11), (0.50, 0.19),
                 (0.42, 0.23), (0.58, 0.23),
                 (0.40, 0.37), (0.60, 0.37),
                 (0.40, 0.50), (0.62, 0.50),
                 (0.46, 0.56), (0.54, 0.56),
                 (0.46, 0.76), (0.54, 0.76),
                 (0.46, 0.96), (0.56, 0.96)
             ),
             lighting: [.any], scene: [.any]),

        pose("fb-shadow-play",
             name: "Shadow Play",
             description: "Subject partially in shadow, one side of face lit dramatically.",
             category: .editorial, difficulty: .hard,
             tips: [
                 "Light — Expose for the lit side only.",
                 "Pose — Tilt the lit side toward the camera.",
                 "Backdrop — Dark background for max contrast."
             ],
             keypoints: skel(
                 (0.50, 0.13), (0.50, 0.21),
                 (0.40, 0.25), (0.60, 0.25),
                 (0.36, 0.40), (0.64, 0.40),
                 (0.38, 0.54), (0.62, 0.54),
                 (0.44, 0.58), (0.56, 0.58),
                 (0.44, 0.78), (0.56, 0.78),
                 (0.44, 0.96), (0.56, 0.96)
             ),
             isPro: true,
             lighting: [.harsh, .studio, .night], scene: [.studio, .city])
    ]
}
