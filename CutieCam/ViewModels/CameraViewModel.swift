//
//  CameraViewModel.swift
//  CutieCam
//
//  ViewModel for camera functionality
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    @Published var cameraService = CameraService()
    @Published var filterService = FilterService()
    
    @Published var selectedFilter: Filter?
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isCapturing = false
    @Published var showingEditor = false
    @Published var showingFilterSelector = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen to camera errors
        cameraService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Camera Setup
    func setupCamera() async {
        await cameraService.checkAuthorization()
        
        guard cameraService.isAuthorized else {
            errorMessage = "Camera access is required to use this app."
            return
        }
        
        do {
            try await cameraService.setupCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Capture Photo
    func capturePhoto() async {
        guard !isCapturing else { return }
        isCapturing = true
        
        do {
            let image = try await cameraService.capturePhoto(with: selectedFilter)
            capturedImage = image
            
            // Apply filter if selected
            if let filter = selectedFilter {
                processedImage = try await filterService.applyFilter(filter, to: image)
            } else {
                processedImage = image
            }
            
            showingEditor = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCapturing = false
    }
    
    // MARK: - Filter Selection
    func selectFilter(_ filter: Filter?) {
        selectedFilter = filter
    }
    
    // MARK: - Camera Controls
    func switchCamera() async {
        do {
            try await cameraService.switchCamera()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleFlash() {
        cameraService.toggleFlash()
    }
    
    func adjustZoom(_ zoom: CGFloat) {
        cameraService.setZoom(zoom)
    }
    
    // MARK: - Save Photo
    func savePhoto(_ image: UIImage) async throws {
        // Save to photo library
        try await PhotoLibraryService.shared.savePhoto(image)
    }
}

