import Foundation
import AVFoundation
import CoreImage
import UIKit

protocol CameraFrameReceiver: AnyObject {
    func camera(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraService: NSObject {
    enum AuthorizationState { case unknown, authorized, denied, notDetermined }

    let session = AVCaptureSession()
    weak var frameReceiver: CameraFrameReceiver?

    private let sessionQueue = DispatchQueue(label: "posra.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "posra.camera.video",
                                                 qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .back
    private var videoDevice: AVCaptureDevice?
    private var photoDelegate: PhotoCaptureDelegate?

    // Sensor readings polled on every frame
    private(set) var currentISO: Float = 0
    private(set) var currentWhiteBalanceKelvin: Float = 0
    private(set) var currentExposureDuration: CMTime = .zero

    var authorizationState: AuthorizationState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .unknown
        }
    }

    override init() {
        super.init()
    }

    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        switch authorizationState {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    func configureAndStart() {
        sessionQueue.async {
            self.configureSession()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func switchCamera() {
        sessionQueue.async {
            self.currentPosition = (self.currentPosition == .back) ? .front : .back
            self.configureSession(reset: true)
        }
    }

    // MARK: - Photo capture

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async {
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .balanced
            if let connection = self.photoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
            }
            let delegate = PhotoCaptureDelegate(completion: completion)
            self.photoDelegate = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Session

    private func configureSession(reset: Bool = false) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if reset {
            session.inputs.forEach { session.removeInput($0) }
        }

        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: currentPosition),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            return
        }
        videoDevice = device

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Video data output — always (re)attach exactly once
        if !session.outputs.contains(videoOutput) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        }
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if currentPosition == .front {
                connection.isVideoMirrored = true
            }
        }

        // Photo output
        if !session.outputs.contains(photoOutput) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
    }
}

// MARK: - Sample Buffer Delegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Pull sensor readings
        if let device = videoDevice {
            currentISO = device.iso
            currentExposureDuration = device.exposureDuration
            let gains = device.deviceWhiteBalanceGains
            let tempTint = device.temperatureAndTintValues(for: gains)
            currentWhiteBalanceKelvin = tempTint.temperature
        }
        frameReceiver?.camera(self, didOutput: sampleBuffer)
    }
}

// MARK: - Photo delegate

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            print("Photo capture error: \(error)")
            DispatchQueue.main.async { self.completion(nil) }
            return
        }
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        DispatchQueue.main.async { self.completion(image) }
    }
}
