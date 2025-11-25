//
//  Filter.swift
//  CutieCam
//
//  Film camera & compact digital camera aesthetic filters
//

import Foundation
import SwiftUI

// MARK: - Filter Model
struct Filter: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let nameLocalized: LocalizedString
    let description: String
    let thumbnailName: String
    let creatorId: String?
    let creatorName: String?
    let price: Double // 0 for free filters
    let isPremium: Bool
    let isUserGenerated: Bool
    let downloads: Int
    let rating: Double
    let tags: [FilterTag]
    var parameters: FilterParameters
    let dateCreated: Date
    
    // Film camera aesthetics
    var aestheticStyle: AestheticStyle
    
    init(
        id: UUID = UUID(),
        name: String,
        nameLocalized: LocalizedString,
        description: String,
        thumbnailName: String,
        creatorId: String? = nil,
        creatorName: String? = nil,
        price: Double = 0,
        isPremium: Bool = false,
        isUserGenerated: Bool = false,
        downloads: Int = 0,
        rating: Double = 5.0,
        tags: [FilterTag] = [],
        parameters: FilterParameters,
        aestheticStyle: AestheticStyle,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nameLocalized = nameLocalized
        self.description = description
        self.thumbnailName = thumbnailName
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.price = price
        self.isPremium = isPremium
        self.isUserGenerated = isUserGenerated
        self.downloads = downloads
        self.rating = rating
        self.tags = tags
        self.parameters = parameters
        self.aestheticStyle = aestheticStyle
        self.dateCreated = dateCreated
    }
}

// MARK: - Filter Parameters
struct FilterParameters: Codable, Hashable {
    // Film grain & texture
    var grainIntensity: Double // 0-1
    var grainSize: Double // 0-1
    
    // Color grading (film aesthetic)
    var temperature: Double // -1 to 1 (cool to warm)
    var tint: Double // -1 to 1 (green to magenta)
    var saturation: Double // 0-2
    var contrast: Double // 0-2
    var exposure: Double // -2 to 2
    var highlights: Double // -1 to 1
    var shadows: Double // -1 to 1
    
    // Film-specific effects
    var vignette: Double // 0-1
    var lightLeakIntensity: Double // 0-1
    var lightLeakColor: String // hex color
    var fadeAmount: Double // 0-1 (faded film look)
    
    // Compact digital camera effects
    var digitalNoise: Double // 0-1
    var sharpness: Double // 0-2
    var dateStampEnabled: Bool
    var dateStampStyle: DateStampStyle
    
    // Color manipulation (inspired by viral film looks)
    var colorCurve: ColorCurve
    var halation: Double // 0-1 (glow around highlights)
    
    static var `default`: FilterParameters {
        FilterParameters(
            grainIntensity: 0.3,
            grainSize: 0.5,
            temperature: 0,
            tint: 0,
            saturation: 1.0,
            contrast: 1.1,
            exposure: 0,
            highlights: -0.1,
            shadows: 0.1,
            vignette: 0.2,
            lightLeakIntensity: 0,
            lightLeakColor: "#FFAA00",
            fadeAmount: 0.1,
            digitalNoise: 0.1,
            sharpness: 1.0,
            dateStampEnabled: false,
            dateStampStyle: .vintage,
            colorCurve: .neutral,
            halation: 0.2
        )
    }
}

// MARK: - Aesthetic Styles
enum AestheticStyle: String, Codable, CaseIterable {
    case filmVintage = "film_vintage"
    case film35mm = "film_35mm"
    case instantPolaroid = "instant_polaroid"
    case compactDigital = "compact_digital"
    case disposableCamera = "disposable_camera"
    case cinematic = "cinematic"
    case dreamy = "dreamy"
    case viralKpop = "viral_kpop"
    case softAesthetic = "soft_aesthetic"
    case y2k = "y2k"
    
    var displayName: String {
        switch self {
        case .filmVintage: return "Film Vintage"
        case .film35mm: return "35mm Film"
        case .instantPolaroid: return "Instant Film"
        case .compactDigital: return "Digital Compact"
        case .disposableCamera: return "Disposable"
        case .cinematic: return "Cinematic"
        case .dreamy: return "Dreamy"
        case .viralKpop: return "K-Pop Style"
        case .softAesthetic: return "Soft Aesthetic"
        case .y2k: return "Y2K Digital"
        }
    }
    
    var icon: String {
        switch self {
        case .filmVintage: return "camera.fill"
        case .film35mm: return "camera.aperture"
        case .instantPolaroid: return "photo.fill"
        case .compactDigital: return "camera.compact"
        case .disposableCamera: return "camera.metering.center.weighted"
        case .cinematic: return "film.fill"
        case .dreamy: return "sparkles"
        case .viralKpop: return "star.fill"
        case .softAesthetic: return "heart.fill"
        case .y2k: return "dial.max.fill"
        }
    }
}

// MARK: - Color Curve
enum ColorCurve: String, Codable {
    case neutral
    case warmVintage
    case coolBlue
    case fadedPink
    case greenTint
    case sepia
    case blackAndWhite
    case viralOrange
    case softPeach
}

// MARK: - Date Stamp Style
enum DateStampStyle: String, Codable {
    case vintage
    case compact
    case polaroid
    case modern
    case custom
}

// MARK: - Filter Tags
enum FilterTag: String, Codable, CaseIterable {
    case trending
    case popular
    case new
    case free
    case premium
    case film
    case digital
    case vintage
    case modern
    case soft
    case vibrant
    case dark
    case light
    case kpop
    case aesthetic
    case y2k
    case cinematic
}

// MARK: - Localized String
struct LocalizedString: Codable, Hashable {
    let en: String
    let th: String
    
    func get(for locale: String = Locale.current.language.languageCode?.identifier ?? "en") -> String {
        locale.contains("th") ? th : en
    }
}

// MARK: - Predefined Filters (Viral Inspired)
extension Filter {
    static let presetFilters: [Filter] = [
        // Trending Film Look
        Filter(
            name: "Film Dreams",
            nameLocalized: LocalizedString(en: "Film Dreams", th: "ฟิล์มดรีม"),
            description: "Soft vintage film with warm tones",
            thumbnailName: "filter_film_dreams",
            price: 0,
            tags: [.trending, .free, .film, .soft],
            parameters: FilterParameters(
                grainIntensity: 0.25,
                grainSize: 0.5,
                temperature: 0.15,
                tint: 0.05,
                saturation: 0.95,
                contrast: 1.1,
                exposure: 0.08,
                highlights: -0.1,
                shadows: 0.1,
                vignette: 0.2,
                lightLeakIntensity: 0.15,
                lightLeakColor: "#FFD700",
                fadeAmount: 0.15,
                digitalNoise: 0,
                sharpness: 0.9,
                dateStampEnabled: false,
                dateStampStyle: .vintage,
                colorCurve: .warmVintage,
                halation: 0.2
            ),
            aestheticStyle: .filmVintage
        ),
        
        // K-Pop Viral Style
        Filter(
            name: "K-Pop Glow",
            nameLocalized: LocalizedString(en: "K-Pop Glow", th: "เคป็อปโกลว์"),
            description: "Soft, glowing skin like K-pop idols",
            thumbnailName: "filter_kpop_glow",
            price: 0,
            tags: [.trending, .popular, .kpop, .soft],
            parameters: FilterParameters(
                grainIntensity: 0.08,
                grainSize: 0.3,
                temperature: 0.12,
                tint: -0.03,
                saturation: 1.05,
                contrast: 1.03,
                exposure: 0.15,
                highlights: 0.08,
                shadows: 0.04,
                vignette: 0.08,
                lightLeakIntensity: 0.12,
                lightLeakColor: "#FFE5E5",
                fadeAmount: 0.03,
                digitalNoise: 0,
                sharpness: 0.85,
                dateStampEnabled: false,
                dateStampStyle: .modern,
                colorCurve: .softPeach,
                halation: 0.25
            ),
            aestheticStyle: .viralKpop
        ),
        
        // Disposable Camera
        Filter(
            name: "Disposable",
            nameLocalized: LocalizedString(en: "Disposable", th: "ดิสโพสเซเบิล"),
            description: "Y2K disposable camera vibes",
            thumbnailName: "filter_disposable",
            price: 0,
            tags: [.trending, .y2k, .film, .vibrant],
            parameters: FilterParameters(
                grainIntensity: 0.35,
                grainSize: 0.6,
                temperature: 0.05,
                tint: 0,
                saturation: 1.15,
                contrast: 1.2,
                exposure: 0.1,
                highlights: -0.15,
                shadows: 0.12,
                vignette: 0.25,
                lightLeakIntensity: 0.2,
                lightLeakColor: "#FF6B35",
                fadeAmount: 0.1,
                digitalNoise: 0.15,
                sharpness: 1.1,
                dateStampEnabled: false,
                dateStampStyle: .compact,
                colorCurve: .viralOrange,
                halation: 0.18
            ),
            aestheticStyle: .disposableCamera
        ),
        
        // Compact Digital (Y2K)
        Filter(
            name: "Y2K Digital",
            nameLocalized: LocalizedString(en: "Y2K Digital", th: "ย้อนยุค 2000"),
            description: "Early 2000s digital camera aesthetic",
            thumbnailName: "filter_y2k",
            price: 0,
            tags: [.popular, .digital, .y2k, .vibrant],
            parameters: FilterParameters(
                grainIntensity: 0.05,
                grainSize: 0.3,
                temperature: -0.08,
                tint: 0,
                saturation: 1.12,
                contrast: 1.15,
                exposure: 0.08,
                highlights: -0.08,
                shadows: 0.08,
                vignette: 0.12,
                lightLeakIntensity: 0,
                lightLeakColor: "#FFFFFF",
                fadeAmount: 0,
                digitalNoise: 0.22,
                sharpness: 1.3,
                dateStampEnabled: false,
                dateStampStyle: .compact,
                colorCurve: .neutral,
                halation: 0.08
            ),
            aestheticStyle: .compactDigital
        ),
        
        // Soft Aesthetic (Instagram Viral)
        Filter(
            name: "Soft Aesthetic",
            nameLocalized: LocalizedString(en: "Soft Aesthetic", th: "ซอฟต์เอสเทติก"),
            description: "Instagram-ready soft dreamy look",
            thumbnailName: "filter_soft",
            price: 0,
            tags: [.trending, .aesthetic, .soft, .light],
            parameters: FilterParameters(
                grainIntensity: 0.12,
                grainSize: 0.4,
                temperature: 0.18,
                tint: 0.04,
                saturation: 0.9,
                contrast: 0.98,
                exposure: 0.18,
                highlights: 0.1,
                shadows: 0.15,
                vignette: 0.15,
                lightLeakIntensity: 0.18,
                lightLeakColor: "#FFF0E5",
                fadeAmount: 0.22,
                digitalNoise: 0,
                sharpness: 0.8,
                dateStampEnabled: false,
                dateStampStyle: .modern,
                colorCurve: .fadedPink,
                halation: 0.28
            ),
            aestheticStyle: .softAesthetic
        ),
        
        // Cinematic Film
        Filter(
            name: "Cinematic",
            nameLocalized: LocalizedString(en: "Cinematic", th: "ซีเนมาติก"),
            description: "Movie-like color grading",
            thumbnailName: "filter_cinematic",
            isPremium: true,
            tags: [.premium, .film, .cinematic, .dark],
            parameters: FilterParameters(
                grainIntensity: 0.28,
                grainSize: 0.5,
                temperature: 0.08,
                tint: -0.08,
                saturation: 1.05,
                contrast: 1.22,
                exposure: -0.02,
                highlights: -0.18,
                shadows: 0.12,
                vignette: 0.3,
                lightLeakIntensity: 0.08,
                lightLeakColor: "#4A90E2",
                fadeAmount: 0.08,
                digitalNoise: 0.04,
                sharpness: 1.1,
                dateStampEnabled: false,
                dateStampStyle: .modern,
                colorCurve: .coolBlue,
                halation: 0.15
            ),
            aestheticStyle: .cinematic
        ),
        
        // Natural - No Filter
        Filter(
            name: "Natural",
            nameLocalized: LocalizedString(en: "Natural", th: "ธรรมชาติ"),
            description: "No filter, original look",
            thumbnailName: "filter_natural",
            price: 0,
            tags: [.free],
            parameters: FilterParameters(
                grainIntensity: 0,
                grainSize: 0,
                temperature: 0,
                tint: 0,
                saturation: 1.0,
                contrast: 1.0,
                exposure: 0,
                highlights: 0,
                shadows: 0,
                vignette: 0,
                lightLeakIntensity: 0,
                lightLeakColor: "#FFFFFF",
                fadeAmount: 0,
                digitalNoise: 0,
                sharpness: 1.0,
                dateStampEnabled: false,
                dateStampStyle: .modern,
                colorCurve: .neutral,
                halation: 0
            ),
            aestheticStyle: .film35mm
        ),
        
        // Black & White Film
        Filter(
            name: "B&W Film",
            nameLocalized: LocalizedString(en: "B&W Film", th: "ขาวดำฟิล์ม"),
            description: "Classic black and white film",
            thumbnailName: "filter_bw",
            price: 0,
            tags: [.free, .film, .vintage],
            parameters: FilterParameters(
                grainIntensity: 0.3,
                grainSize: 0.5,
                temperature: 0,
                tint: 0,
                saturation: 1.0,
                contrast: 1.15,
                exposure: 0.05,
                highlights: -0.1,
                shadows: 0.1,
                vignette: 0.25,
                lightLeakIntensity: 0,
                lightLeakColor: "#FFFFFF",
                fadeAmount: 0.1,
                digitalNoise: 0,
                sharpness: 1.05,
                dateStampEnabled: false,
                dateStampStyle: .vintage,
                colorCurve: .blackAndWhite,
                halation: 0.15
            ),
            aestheticStyle: .filmVintage
        )
    ]
}

