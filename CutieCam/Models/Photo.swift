//
//  Photo.swift
//  CutieCam
//
//  Photo model for captured and edited images
//

import Foundation
import UIKit

// MARK: - Photo Model
struct Photo: Identifiable, Codable {
    let id: UUID
    var imagePath: String // Local or cloud URL
    var thumbnailPath: String?
    var appliedFilter: Filter?
    var customAdjustments: FilterParameters?
    var dateCreated: Date
    var dateTaken: Date
    var isEdited: Bool
    var isFavorite: Bool
    var tags: [String]
    var location: String?
    
    // Metadata
    var cameraSettings: CameraSettings?
    
    init(
        id: UUID = UUID(),
        imagePath: String,
        thumbnailPath: String? = nil,
        appliedFilter: Filter? = nil,
        customAdjustments: FilterParameters? = nil,
        dateCreated: Date = Date(),
        dateTaken: Date = Date(),
        isEdited: Bool = false,
        isFavorite: Bool = false,
        tags: [String] = [],
        location: String? = nil,
        cameraSettings: CameraSettings? = nil
    ) {
        self.id = id
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.appliedFilter = appliedFilter
        self.customAdjustments = customAdjustments
        self.dateCreated = dateCreated
        self.dateTaken = dateTaken
        self.isEdited = isEdited
        self.isFavorite = isFavorite
        self.tags = tags
        self.location = location
        self.cameraSettings = cameraSettings
    }
}

// MARK: - Camera Settings
struct CameraSettings: Codable {
    var iso: Int?
    var shutterSpeed: String?
    var aperture: String?
    var focalLength: String?
    var whiteBalance: String?
    var flashMode: String?
}

