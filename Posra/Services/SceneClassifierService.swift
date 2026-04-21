import CoreMedia
import CoreVideo
import Foundation
import Vision

/// Classifies the scene (indoor/outdoor/beach/city/park/studio) from a single frame
/// using Vision's built-in `VNClassifyImageRequest`. Runs at most once per
/// `minimumInterval` seconds; callers can poll via `process(_:)` on every frame.
final class SceneClassifierService {
    /// Minimum seconds between classification requests.
    var minimumInterval: TimeInterval = 1.2

    private let queue = DispatchQueue(label: "posra.scene", qos: .utility)
    private var lastRun: Date = .distantPast
    private var inFlight = false

    var onClassify: ((Scene) -> Void)?

    func process(sampleBuffer: CMSampleBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastRun) >= minimumInterval else { return }
        guard !inFlight else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        inFlight = true
        lastRun = now

        queue.async { [weak self] in
            guard let self else { return }
            defer { self.inFlight = false }
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: .up,
                                                options: [:])
            let request = VNClassifyImageRequest()
            do {
                try handler.perform([request])
            } catch {
                return
            }
            guard let observations = request.results as? [VNClassificationObservation] else { return }
            let scene = Self.mapToScene(observations)
            DispatchQueue.main.async {
                self.onClassify?(scene)
            }
        }
    }

    // MARK: - Mapping

    /// Maps Vision's open-vocabulary labels to our coarse `Scene` enum.
    /// We rank the top hits by confidence and pick the first FotoPose-relevant match.
    static func mapToScene(_ observations: [VNClassificationObservation]) -> Scene {
        let top = observations
            .filter { $0.confidence > 0.25 }
            .prefix(30)

        for obs in top {
            if let mapped = bucket(for: obs.identifier) {
                return mapped
            }
        }
        return .any
    }

    private static func bucket(for identifier: String) -> Scene? {
        let id = identifier.lowercased()

        if beachKeywords.contains(where: id.contains)   { return .beach }
        if parkKeywords.contains(where: id.contains)    { return .park }
        if cityKeywords.contains(where: id.contains)    { return .city }
        if studioKeywords.contains(where: id.contains)  { return .studio }
        if indoorKeywords.contains(where: id.contains)  { return .indoor }
        if outdoorKeywords.contains(where: id.contains) { return .outdoor }
        return nil
    }

    // Keyword lists are intentionally small and biased toward photography terms.
    private static let beachKeywords = [
        "beach", "seashore", "coast", "shore", "ocean", "sea",
        "dune", "sand", "surf", "lagoon"
    ]
    private static let parkKeywords = [
        "park", "garden", "forest", "woods", "meadow", "field",
        "tree", "flower", "botanical", "grassland", "lawn"
    ]
    private static let cityKeywords = [
        "street", "urban", "city", "downtown", "building", "skyscraper",
        "alley", "storefront", "plaza", "sidewalk", "boulevard", "cafe"
    ]
    private static let studioKeywords = [
        "studio", "backdrop", "softbox", "seamless", "photo_studio"
    ]
    private static let indoorKeywords = [
        "indoor", "room", "interior", "kitchen", "bedroom", "living_room",
        "library", "restaurant", "gallery", "museum", "office", "hallway",
        "lobby", "bathroom", "hotel"
    ]
    private static let outdoorKeywords = [
        "outdoor", "landscape", "mountain", "hill", "sky", "horizon",
        "countryside", "rural"
    ]
}
