import Foundation
import Vision
import AVFoundation
import CoreGraphics

protocol VisionServiceDelegate: AnyObject {
    func visionService(_ service: VisionService, didUpdate detection: VisionFrame)
}

struct VisionFrame {
    let personCount: Int
    let bodyPose: BodyPoseObservation?
    let posture: Posture
    /// Normalized bounding rect of the primary subject, top-left origin (0...1).
    let primaryPersonRect: CGRect?
}

final class VisionService {
    weak var delegate: VisionServiceDelegate?

    /// Throttle — process every Nth frame to hit ~6 Hz on 30fps feeds.
    var frameStride: Int = 5
    private var frameCounter: Int = 0
    private let visionQueue = DispatchQueue(label: "posra.vision", qos: .userInitiated)
    private var inFlight: Bool = false

    func process(sampleBuffer: CMSampleBuffer) {
        frameCounter &+= 1
        guard frameCounter % frameStride == 0 else { return }
        guard !inFlight else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        inFlight = true
        let orientation = CGImagePropertyOrientation.up

        visionQueue.async { [weak self] in
            guard let self else { return }
            defer { self.inFlight = false }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: orientation,
                                                options: [:])

            let personRequest = VNDetectHumanRectanglesRequest()
            personRequest.revision = VNDetectHumanRectanglesRequestRevision2

            let bodyRequest = VNDetectHumanBodyPoseRequest()

            do {
                try handler.perform([personRequest, bodyRequest])
            } catch {
                // Silent — camera keeps feeding frames
                return
            }

            let (personCount, primaryRect) = Self.countPeople(from: personRequest.results)
            let observation = Self.parseBodyPose(bodyRequest.results?.first)
            let posture = Self.classifyPosture(from: observation)

            let frame = VisionFrame(
                personCount: personCount,
                bodyPose: observation,
                posture: posture,
                primaryPersonRect: primaryRect
            )
            DispatchQueue.main.async {
                self.delegate?.visionService(self, didUpdate: frame)
            }
        }
    }

    // MARK: - Parsing helpers

    private static func countPeople(from observations: [VNHumanObservation]?) -> (Int, CGRect?) {
        let results = observations ?? []
        let confident = results.filter { $0.confidence > 0.5 }
        // Normalized Vision rects are bottom-left. Convert to top-left for our overlays.
        let primary = confident
            .max { a, b in a.boundingBox.width * a.boundingBox.height < b.boundingBox.width * b.boundingBox.height }
            .map { box -> CGRect in
                let b = box.boundingBox
                return CGRect(x: b.origin.x, y: 1 - b.origin.y - b.height,
                              width: b.width, height: b.height)
            }
        return (confident.count, primary)
    }

    private static func parseBodyPose(_ observation: VNHumanBodyPoseObservation?) -> BodyPoseObservation? {
        guard let observation else { return nil }
        guard let recognized = try? observation.recognizedPoints(.all) else { return nil }

        var joints: [String: BodyPoseObservation.Joint] = [:]
        let map: [(VNHumanBodyPoseObservation.JointName, String)] = [
            (.nose, "head"),
            (.neck, "neck"),
            (.leftShoulder, "left_shoulder"),
            (.rightShoulder, "right_shoulder"),
            (.leftElbow, "left_elbow"),
            (.rightElbow, "right_elbow"),
            (.leftWrist, "left_wrist"),
            (.rightWrist, "right_wrist"),
            (.leftHip, "left_hip"),
            (.rightHip, "right_hip"),
            (.leftKnee, "left_knee"),
            (.rightKnee, "right_knee"),
            (.leftAnkle, "left_ankle"),
            (.rightAnkle, "right_ankle")
        ]
        for (name, key) in map {
            guard let point = recognized[name], point.confidence > 0.25 else { continue }
            // Vision: normalized, bottom-left origin. Convert to top-left.
            let converted = CGPoint(x: point.location.x,
                                    y: 1 - point.location.y)
            joints[key] = BodyPoseObservation.Joint(
                name: key,
                position: converted,
                confidence: point.confidence
            )
        }
        return joints.isEmpty ? nil : BodyPoseObservation(joints: joints)
    }

    private static func classifyPosture(from observation: BodyPoseObservation?) -> Posture {
        guard let observation else { return .unknown }
        guard
            let leftHip = observation.joints["left_hip"]?.position,
            let rightHip = observation.joints["right_hip"]?.position,
            let leftKnee = observation.joints["left_knee"]?.position,
            let rightKnee = observation.joints["right_knee"]?.position,
            let leftAnkle = observation.joints["left_ankle"]?.position,
            let rightAnkle = observation.joints["right_ankle"]?.position
        else {
            return .unknown
        }

        let hipY = (leftHip.y + rightHip.y) / 2
        let kneeY = (leftKnee.y + rightKnee.y) / 2
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2

        let hipToKnee = kneeY - hipY
        let kneeToAnkle = ankleY - kneeY

        if hipToKnee < 0.05 && kneeToAnkle < 0.05 {
            return .sitting
        }
        if hipToKnee > 0.12 && kneeToAnkle > 0.12 {
            return .standing
        }
        return .crouching
    }
}
