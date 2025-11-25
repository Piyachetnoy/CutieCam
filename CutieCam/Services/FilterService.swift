//
//  FilterService.swift
//  CutieCam
//
//  Filter processing service with film aesthetic effects
//

import Foundation
import UIKit
import CoreImage
import Accelerate
import Combine

// MARK: - Filter Service
@MainActor
class FilterService: ObservableObject {
    @Published var availableFilters: [Filter] = []
    @Published var isProcessing = false
    
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    init() {
        loadPresetFilters()
    }
    
    // MARK: - Load Filters
    func loadPresetFilters() {
        availableFilters = Filter.presetFilters
    }
    
    // MARK: - Apply Filter to Image
    func applyFilter(_ filter: Filter, to image: UIImage) async throws -> UIImage {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let inputCIImage = CIImage(image: image) else {
            throw FilterError.invalidImage
        }
        
        var outputImage = inputCIImage
        let params = filter.parameters
        
        // Apply color adjustments
        outputImage = try applyColorAdjustments(to: outputImage, params: params)
        
        // Apply film grain
        if params.grainIntensity > 0 {
            outputImage = try applyFilmGrain(to: outputImage, intensity: params.grainIntensity, size: params.grainSize)
        }
        
        // Apply vignette
        if params.vignette > 0 {
            outputImage = try applyVignette(to: outputImage, intensity: params.vignette)
        }
        
        // Apply light leak
        if params.lightLeakIntensity > 0 {
            outputImage = try applyLightLeak(to: outputImage, intensity: params.lightLeakIntensity, color: params.lightLeakColor)
        }
        
        // Apply fade (faded film look)
        if params.fadeAmount > 0 {
            outputImage = try applyFade(to: outputImage, amount: params.fadeAmount)
        }
        
        // Apply halation (glow around highlights)
        if params.halation > 0 {
            outputImage = try applyHalation(to: outputImage, intensity: params.halation)
        }
        
        // Apply digital noise (for compact camera aesthetic)
        if params.digitalNoise > 0 {
            outputImage = try applyDigitalNoise(to: outputImage, intensity: params.digitalNoise)
        }
        
        // Apply date stamp if enabled
        if params.dateStampEnabled {
            outputImage = try applyDateStamp(to: outputImage, style: params.dateStampStyle)
        }
        
        // Render final image
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw FilterError.renderingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Color Adjustments
    private func applyColorAdjustments(to image: CIImage, params: FilterParameters) throws -> CIImage {
        var outputImage = image
        
        // Temperature & Tint
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CIVector(x: 6500 + params.temperature * 2000, y: 0), forKey: "inputNeutral")
            temperatureFilter.setValue(CIVector(x: 6500, y: params.tint * 100), forKey: "inputTargetNeutral")
            if let output = temperatureFilter.outputImage {
                outputImage = output
            }
        }
        
        // Exposure
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(params.exposure, forKey: kCIInputEVKey)
            if let output = exposureFilter.outputImage {
                outputImage = output
            }
        }
        
        // Contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(params.contrast, forKey: kCIInputContrastKey)
            contrastFilter.setValue(params.saturation, forKey: kCIInputSaturationKey)
            if let output = contrastFilter.outputImage {
                outputImage = output
            }
        }
        
        // Highlights & Shadows
        if let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
            highlightShadowFilter.setValue(outputImage, forKey: kCIInputImageKey)
            highlightShadowFilter.setValue(1.0 + params.highlights, forKey: "inputHighlightAmount")
            highlightShadowFilter.setValue(params.shadows, forKey: "inputShadowAmount")
            if let output = highlightShadowFilter.outputImage {
                outputImage = output
            }
        }
        
        return outputImage
    }
    
    // MARK: - Film Grain
    private func applyFilmGrain(to image: CIImage, intensity: Double, size: Double) throws -> CIImage {
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else {
            return image
        }
        
        guard let noiseImage = noiseFilter.outputImage else {
            return image
        }
        
        // Scale noise
        let scaled = noiseImage.transformed(by: CGAffineTransform(scaleX: size * 5, y: size * 5))
        
        // Crop to image size
        let cropped = scaled.cropped(to: image.extent)
        
        // Blend with original
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else {
            return image
        }
        
        blendFilter.setValue(cropped, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        guard let blendedImage = blendFilter.outputImage else {
            return image
        }
        
        // Adjust opacity
        guard let opacityFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        
        opacityFilter.setValue(blendedImage, forKey: kCIInputImageKey)
        opacityFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        opacityFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: intensity), forKey: "inputAVector")
        
        return opacityFilter.outputImage ?? image
    }
    
    // MARK: - Vignette
    private func applyVignette(to image: CIImage, intensity: Double) throws -> CIImage {
        guard let vignetteFilter = CIFilter(name: "CIVignette") else {
            return image
        }
        
        vignetteFilter.setValue(image, forKey: kCIInputImageKey)
        vignetteFilter.setValue(intensity * 2, forKey: kCIInputIntensityKey)
        vignetteFilter.setValue(0.5, forKey: kCIInputRadiusKey)
        
        return vignetteFilter.outputImage ?? image
    }
    
    // MARK: - Light Leak
    private func applyLightLeak(to image: CIImage, intensity: Double, color: String) throws -> CIImage {
        // Create gradient for light leak effect
        let colorObj = UIColor(hex: color) ?? .orange
        
        guard let gradientFilter = CIFilter(name: "CIRadialGradient") else {
            return image
        }
        
        let center = CIVector(x: image.extent.width * 0.8, y: image.extent.height * 0.2)
        gradientFilter.setValue(center, forKey: "inputCenter")
        gradientFilter.setValue(image.extent.width * 0.5, forKey: "inputRadius0")
        gradientFilter.setValue(image.extent.width * 1.2, forKey: "inputRadius1")
        gradientFilter.setValue(CIColor(color: colorObj.withAlphaComponent(intensity)), forKey: "inputColor0")
        gradientFilter.setValue(CIColor(color: .clear), forKey: "inputColor1")
        
        guard let gradientImage = gradientFilter.outputImage?.cropped(to: image.extent) else {
            return image
        }
        
        // Blend with original
        guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else {
            return image
        }
        
        blendFilter.setValue(gradientImage, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Fade Effect
    private func applyFade(to image: CIImage, amount: Double) throws -> CIImage {
        // Fade by reducing contrast in blacks
        guard let fadeFilter = CIFilter(name: "CIColorControls") else {
            return image
        }
        
        fadeFilter.setValue(image, forKey: kCIInputImageKey)
        fadeFilter.setValue(1.0 - amount * 0.3, forKey: kCIInputContrastKey)
        fadeFilter.setValue(amount * 0.3, forKey: kCIInputBrightnessKey)
        
        return fadeFilter.outputImage ?? image
    }
    
    // MARK: - Halation (Highlight Glow)
    private func applyHalation(to image: CIImage, intensity: Double) throws -> CIImage {
        // Extract highlights
        guard let highlightFilter = CIFilter(name: "CIColorControls") else {
            return image
        }
        
        highlightFilter.setValue(image, forKey: kCIInputImageKey)
        highlightFilter.setValue(2.0, forKey: kCIInputContrastKey)
        highlightFilter.setValue(0.5, forKey: kCIInputBrightnessKey)
        
        guard var highlights = highlightFilter.outputImage else {
            return image
        }
        
        // Blur highlights
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(highlights, forKey: kCIInputImageKey)
            blurFilter.setValue(intensity * 20, forKey: kCIInputRadiusKey)
            highlights = blurFilter.outputImage?.cropped(to: image.extent) ?? highlights
        }
        
        // Blend with original
        guard let blendFilter = CIFilter(name: "CIAdditionCompositing") else {
            return image
        }
        
        blendFilter.setValue(highlights, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Digital Noise
    private func applyDigitalNoise(to image: CIImage, intensity: Double) throws -> CIImage {
        // Similar to grain but more uniform (digital camera artifact)
        return try applyFilmGrain(to: image, intensity: intensity * 0.5, size: 0.3)
    }
    
    // MARK: - Date Stamp
    private func applyDateStamp(to image: CIImage, style: DateStampStyle) throws -> CIImage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Create text image
        let font = UIFont(name: "Courier", size: style == .vintage ? 24 : 18) ?? UIFont.systemFont(ofSize: 18)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style == .vintage ? UIColor.orange : UIColor.white
        ]
        
        let textSize = (dateString as NSString).size(withAttributes: textAttributes)
        let textRect = CGRect(origin: .zero, size: textSize)
        
        UIGraphicsBeginImageContextWithOptions(textSize, false, 0)
        (dateString as NSString).draw(in: textRect, withAttributes: textAttributes)
        guard let textImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        
        guard let textCIImage = CIImage(image: textImage) else {
            return image
        }
        
        // Position stamp
        let padding: CGFloat = 20
        let xPosition = image.extent.width - textSize.width - padding
        let yPosition = padding
        
        let positionedText = textCIImage.transformed(by: CGAffineTransform(translationX: xPosition, y: yPosition))
        
        // Composite with original
        guard let compositeFilter = CIFilter(name: "CISourceOverCompositing") else {
            return image
        }
        
        compositeFilter.setValue(positionedText, forKey: kCIInputImageKey)
        compositeFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return compositeFilter.outputImage ?? image
    }
}

// MARK: - Filter Error
enum FilterError: LocalizedError {
    case invalidImage
    case filterNotFound
    case renderingFailed
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .filterNotFound:
            return "Filter not found"
        case .renderingFailed:
            return "Failed to render filtered image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        var hexColor = hex
        if hexColor.hasPrefix("#") {
            hexColor.remove(at: hexColor.startIndex)
        }
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                a = 1.0
                
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        
        return nil
    }
}

