//
//  PhotoLibraryService.swift
//  CutieCam
//
//  Service for saving photos to library
//

import Foundation
import UIKit
import Photos

class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    
    private init() {}
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }
    
    // MARK: - Save Photo
    func savePhoto(_ image: UIImage) async throws {
        let authorized = await requestAuthorization()
        guard authorized else {
            throw PhotoLibraryError.accessDenied
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }
    }
}

// MARK: - Errors
enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo library access denied"
        case .saveFailed:
            return "Failed to save photo"
        }
    }
}

