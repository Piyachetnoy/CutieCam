//
//  CameraService.swift
//  CutieCam
//
//  Camera service using AVFoundation
//

import Foundation
import AVFoundation
import UIKit
import Combine
import SwiftUI

// MARK: - Camera Service
@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isCameraReady = false
    @Published var capturedImage: UIImage?
    @Published var error: CameraError?
    @Published var currentZoom: CGFloat = 1.0
    @Published var isFlashOn = false
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var sessionQueue = DispatchQueue(label: "com.cutiecam.camera.sessionqueue")
    
    // Filter processing
    private var currentFilter: Filter?
    
    override init() {
        super.init()
    }
    
    // MARK: - Authorization
    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
            error = .accessDenied
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Setup Camera
    func setupCamera() async throws {
        guard isAuthorized else {
            throw CameraError.accessDenied
        }
        
        let position = cameraPosition
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.sessionNotReady)
                    return
                }
                
                Task { @MainActor in
                    do {
                        try await self.configureCaptureSession(position: position)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        await startSession()
    }
    
    private func configureCaptureSession(position: AVCaptureDevice.Position) async throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Set session preset for high quality
        session.sessionPreset = .photo
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraError.deviceNotAvailable
        }
        
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
        } else {
            throw CameraError.inputError
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            throw CameraError.outputError
        }
    }
    
    // MARK: - Session Control
    func startSession() async {
        guard !session.isRunning else { return }
        
        let sessionRef = session
        sessionQueue.async { [weak self] in
            sessionRef.startRunning()
            Task { @MainActor in
                self?.isCameraReady = true
            }
        }
    }
    
    func stopSession() async {
        guard session.isRunning else { return }
        
        let sessionRef = session
        sessionQueue.async { [weak self] in
            sessionRef.stopRunning()
            Task { @MainActor in
                self?.isCameraReady = false
            }
        }
    }
    
    // MARK: - Capture Photo
    func capturePhoto(with filter: Filter?) async throws -> UIImage {
        guard isCameraReady else {
            throw CameraError.sessionNotReady
        }
        
        currentFilter = filter
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        return try await withCheckedThrowingContinuation { continuation in
            let photoCaptureDelegate = PhotoCaptureDelegate { result in
                continuation.resume(with: result)
            }
            photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate)
        }
    }
    
    // MARK: - Camera Controls
    func switchCamera() async throws {
        cameraPosition = cameraPosition == .back ? .front : .back
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Remove existing input
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Add new input for switched camera
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            throw CameraError.deviceNotAvailable
        }
        
        let newInput = try AVCaptureDeviceInput(device: newDevice)
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoDeviceInput = newInput
        } else {
            throw CameraError.inputError
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func setZoom(_ zoom: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(zoom, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
            currentZoom = device.videoZoomFactor
        } catch {
            print("Error setting zoom: \(error)")
        }
    }
    
    // MARK: - Get Preview Layer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - Photo Capture Delegate
private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void
    
    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        completion(.success(image))
    }
}

// MARK: - Camera Errors
enum CameraError: LocalizedError {
    case accessDenied
    case deviceNotAvailable
    case inputError
    case outputError
    case sessionNotReady
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Camera access denied. Please enable camera access in Settings."
        case .deviceNotAvailable:
            return "Camera device not available."
        case .inputError:
            return "Unable to add camera input."
        case .outputError:
            return "Unable to add photo output."
        case .sessionNotReady:
            return "Camera session not ready."
        case .imageProcessingFailed:
            return "Failed to process captured image."
        }
    }
}

