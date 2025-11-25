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
    
    nonisolated let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var sessionQueue = DispatchQueue(label: "com.cutiecam.camera.sessionqueue")
    
    // Filter processing
    private var currentFilter: Filter?
    
    // Keep strong reference to photo capture delegate
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    
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
        
        try await configureCaptureSession(position: position)
        
        await startSession()
    }
    
    private func configureCaptureSession(position: AVCaptureDevice.Position) async throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Remove existing inputs and outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Set session preset for high quality
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        } else {
            session.sessionPreset = .high
        }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Error: Camera device not available for position: \(position)")
            throw CameraError.deviceNotAvailable
        }
        
        print("Found video device: \(videoDevice.localizedName)")
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                print("Successfully added camera input")
            } else {
                print("Error: Cannot add camera input to session")
                throw CameraError.inputError
            }
        } catch {
            print("Error creating camera input: \(error.localizedDescription)")
            throw CameraError.inputError
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            print("Successfully added photo output")
            
            // iOS version compatibility for photo quality settings
            if #available(iOS 17.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            // Set maximum photo dimensions for high resolution capture (iOS 16+)
            if #available(iOS 16.0, *) {
                // Get the device's maximum photo dimensions
                if let dimensions = videoDevice.activeFormat.supportedMaxPhotoDimensions.first {
                    photoOutput.maxPhotoDimensions = dimensions
                    print("Set max photo dimensions: \(dimensions.width)x\(dimensions.height)")
                }
            }
            
            // Configure photo output settings
            photoOutput.isHighResolutionCaptureEnabled = true
            
        } else {
            print("Error: Cannot add photo output to session")
            throw CameraError.outputError
        }
    }
    
    // MARK: - Session Control
    func startSession() async {
        guard !session.isRunning else { 
            print("Session already running")
            await MainActor.run {
                self.isCameraReady = true
            }
            return 
        }
        
        print("Starting camera session...")
        
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                self.session.startRunning()
                print("Camera session started: \(self.session.isRunning)")
                continuation.resume()
            }
        }
        
        await MainActor.run {
            self.isCameraReady = self.session.isRunning
            print("Camera ready: \(self.isCameraReady)")
        }
    }
    
    func stopSession() async {
        guard session.isRunning else { return }
        
        print("Stopping camera session...")
        
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                self.session.stopRunning()
                print("Camera session stopped")
                continuation.resume()
            }
        }
        
        await MainActor.run {
            self.isCameraReady = false
        }
    }
    
    // MARK: - Capture Photo
    func capturePhoto(with filter: Filter?) async throws -> UIImage {
        guard isCameraReady else {
            throw CameraError.sessionNotReady
        }
        
        guard session.isRunning else {
            throw CameraError.sessionNotReady
        }
        
        currentFilter = filter
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        // Enable high resolution capture
        if #available(iOS 17.0, *) {
            settings.photoQualityPrioritization = .quality
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Keep strong reference to delegate
            self.photoCaptureDelegate = PhotoCaptureDelegate { [weak self] result in
                defer {
                    // Clean up delegate after completion
                    Task { @MainActor in
                        self?.photoCaptureDelegate = nil
                    }
                }
                continuation.resume(with: result)
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self.photoCaptureDelegate!)
        }
    }
    
    // MARK: - Camera Controls
    func switchCamera() async throws {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        print("Switching camera to: \(newPosition == .back ? "back" : "front")")
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Remove existing input
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
            print("Removed current camera input")
        }
        
        // Add new input for switched camera
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            print("Error: Device not available for position: \(newPosition)")
            // Try to restore previous input
            if let oldDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
               let oldInput = try? AVCaptureDeviceInput(device: oldDevice),
               session.canAddInput(oldInput) {
                session.addInput(oldInput)
                videoDeviceInput = oldInput
            }
            throw CameraError.deviceNotAvailable
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
                cameraPosition = newPosition
                print("Successfully switched to \(newPosition == .back ? "back" : "front") camera")
            } else {
                print("Error: Cannot add new camera input")
                // Try to restore previous input
                if let oldDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
                   let oldInput = try? AVCaptureDeviceInput(device: oldDevice),
                   session.canAddInput(oldInput) {
                    session.addInput(oldInput)
                    videoDeviceInput = oldInput
                }
                throw CameraError.inputError
            }
        } catch {
            print("Error creating new camera input: \(error.localizedDescription)")
            // Try to restore previous input
            if let oldDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
               let oldInput = try? AVCaptureDeviceInput(device: oldDevice),
               session.canAddInput(oldInput) {
                session.addInput(oldInput)
                videoDeviceInput = oldInput
            }
            throw error
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
        super.init()
        print("PhotoCaptureDelegate initialized")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Photo capture started")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Photo processing finished")
        
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error: Failed to get image data representation")
            completion(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        print("Image data size: \(imageData.count) bytes")
        
        guard let image = UIImage(data: imageData) else {
            print("Error: Failed to create UIImage from data")
            completion(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        print("Successfully created UIImage: \(image.size)")
        completion(.success(image))
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Capture finished with error: \(error.localizedDescription)")
        } else {
            print("Capture finished successfully")
        }
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

