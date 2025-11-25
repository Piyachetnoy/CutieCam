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
        
        // Step 1: Basic color adjustments (always applied)
        outputImage = applyColorAdjustments(to: outputImage, params: params)
        
        // Step 2: Apply color curves based on aesthetic style
        outputImage = applyColorCurve(to: outputImage, curve: params.colorCurve)
        
        // Step 3: Apply subtle effects only if intensity is significant
        if params.fadeAmount > 0.05 {
            outputImage = applyFade(to: outputImage, amount: params.fadeAmount)
        }
        
        if params.halation > 0.05 {
            outputImage = applyHalation(to: outputImage, intensity: params.halation)
        }
        
        if params.vignette > 0.05 {
            outputImage = applyVignette(to: outputImage, intensity: params.vignette)
        }
        
        if params.lightLeakIntensity > 0.05 {
            outputImage = applyLightLeak(to: outputImage, intensity: params.lightLeakIntensity, color: params.lightLeakColor)
        }
        
        // Step 4: Add texture (grain/noise) - applied last to not be affected by other filters
        if params.grainIntensity > 0.05 {
            outputImage = applyFilmGrain(to: outputImage, intensity: params.grainIntensity, size: params.grainSize)
        }
        
        if params.digitalNoise > 0.05 {
            outputImage = applyDigitalNoise(to: outputImage, intensity: params.digitalNoise)
        }
        
        // Step 5: Apply date stamp (always on top)
        if params.dateStampEnabled {
            outputImage = applyDateStamp(to: outputImage, style: params.dateStampStyle)
        }
        
        // Render final image with proper extent
        let finalExtent = outputImage.extent
        guard let cgImage = context.createCGImage(outputImage, from: finalExtent) else {
            throw FilterError.renderingFailed
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Color Adjustments
    private func applyColorAdjustments(to image: CIImage, params: FilterParameters) -> CIImage {
        var outputImage = image
        
        // Exposure (if not default)
        if abs(params.exposure) > 0.01 {
            if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                exposureFilter.setValue(outputImage, forKey: kCIInputImageKey)
                exposureFilter.setValue(params.exposure, forKey: kCIInputEVKey)
                if let output = exposureFilter.outputImage {
                    outputImage = output
                }
            }
        }
        
        // Contrast & Saturation (if not default)
        if abs(params.contrast - 1.0) > 0.01 || abs(params.saturation - 1.0) > 0.01 {
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(outputImage, forKey: kCIInputImageKey)
                colorFilter.setValue(params.contrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(params.saturation, forKey: kCIInputSaturationKey)
                colorFilter.setValue(1.0, forKey: kCIInputBrightnessKey)
                if let output = colorFilter.outputImage {
                    outputImage = output
                }
            }
        }
        
        // Highlights & Shadows (if not default)
        if abs(params.highlights) > 0.01 || abs(params.shadows) > 0.01 {
            if let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                highlightShadowFilter.setValue(outputImage, forKey: kCIInputImageKey)
                highlightShadowFilter.setValue(1.0 + params.highlights, forKey: "inputHighlightAmount")
                highlightShadowFilter.setValue(params.shadows, forKey: "inputShadowAmount")
                if let output = highlightShadowFilter.outputImage {
                    outputImage = output
                }
            }
        }
        
        // Temperature & Tint (if not default)
        if abs(params.temperature) > 0.01 || abs(params.tint) > 0.01 {
            if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
                temperatureFilter.setValue(outputImage, forKey: kCIInputImageKey)
                temperatureFilter.setValue(CIVector(x: 6500 + params.temperature * 2000, y: 0), forKey: "inputNeutral")
                temperatureFilter.setValue(CIVector(x: 6500, y: params.tint * 100), forKey: "inputTargetNeutral")
                if let output = temperatureFilter.outputImage {
                    outputImage = output
                }
            }
        }
        
        return outputImage
    }
    
    // MARK: - Color Curve Application
    private func applyColorCurve(to image: CIImage, curve: ColorCurve) -> CIImage {
        switch curve {
        case .neutral:
            return image
            
        case .warmVintage:
            return applyWarmVintageCurve(to: image)
            
        case .coolBlue:
            return applyCoolBlueCurve(to: image)
            
        case .fadedPink:
            return applyFadedPinkCurve(to: image)
            
        case .greenTint:
            return applyGreenTintCurve(to: image)
            
        case .sepia:
            return applySepiaFilter(to: image)
            
        case .blackAndWhite:
            return applyBlackAndWhite(to: image)
            
        case .viralOrange:
            return applyViralOrangeCurve(to: image)
            
        case .softPeach:
            return applySoftPeachCurve(to: image)
        }
    }
    
    private func applyWarmVintageCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 1.1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 0.95, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.85, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0.05, y: 0.02, z: 0, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    private func applyCoolBlueCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 0.9, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 0.95, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 1.1, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.05, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    private func applyFadedPinkCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 1.05, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 0.95, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.95, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0.03, y: -0.01, z: 0.02, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    private func applyGreenTintCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 0.95, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1.05, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.95, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0, y: 0.02, z: 0, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    private func applySepiaFilter(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
    
    private func applyBlackAndWhite(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyViralOrangeCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 1.15, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1.0, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.85, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0.08, y: 0.03, z: 0, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    private func applySoftPeachCurve(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 1.05, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1.0, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0.95, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0.04, y: 0.02, z: 0.01, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }
    
    // MARK: - Film Grain (Improved)
    private func applyFilmGrain(to image: CIImage, intensity: Double, size: Double) -> CIImage {
        guard intensity > 0 else { return image }
        
        // Generate noise
        guard let noiseGenerator = CIFilter(name: "CIRandomGenerator"),
              let noiseImage = noiseGenerator.outputImage else {
            return image
        }
        
        // Create monochrome grain
        guard let monochromeFilter = CIFilter(name: "CIColorMonochrome") else {
            return image
        }
        monochromeFilter.setValue(noiseImage, forKey: kCIInputImageKey)
        monochromeFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: kCIInputColorKey)
        monochromeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard var grainImage = monochromeFilter.outputImage else {
            return image
        }
        
        // Scale the grain
        let scale = max(size * 3.0, 0.5)
        grainImage = grainImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Crop to image size
        grainImage = grainImage.cropped(to: image.extent)
        
        // Blend grain with image using overlay mode
        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else {
            return image
        }
        
        // Reduce grain opacity
        guard let opacityFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        opacityFilter.setValue(grainImage, forKey: kCIInputImageKey)
        opacityFilter.setValue(CIVector(x: intensity * 0.3, y: 0, z: 0, w: 0), forKey: "inputRVector")
        opacityFilter.setValue(CIVector(x: 0, y: intensity * 0.3, z: 0, w: 0), forKey: "inputGVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: intensity * 0.3, w: 0), forKey: "inputBVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        opacityFilter.setValue(CIVector(x: 0.5, y: 0.5, z: 0.5, w: 0), forKey: "inputBiasVector")
        
        guard let adjustedGrain = opacityFilter.outputImage else {
            return image
        }
        
        blendFilter.setValue(adjustedGrain, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Vignette (Improved)
    private func applyVignette(to image: CIImage, intensity: Double) -> CIImage {
        guard intensity > 0 else { return image }
        
        guard let vignetteFilter = CIFilter(name: "CIVignette") else {
            return image
        }
        
        vignetteFilter.setValue(image, forKey: kCIInputImageKey)
        vignetteFilter.setValue(intensity * 1.5, forKey: kCIInputIntensityKey)
        vignetteFilter.setValue(0.9, forKey: kCIInputRadiusKey)
        
        return vignetteFilter.outputImage ?? image
    }
    
    // MARK: - Light Leak (Improved)
    private func applyLightLeak(to image: CIImage, intensity: Double, color: String) -> CIImage {
        guard intensity > 0 else { return image }
        
        let colorObj = UIColor(hex: color) ?? .orange
        
        guard let gradientFilter = CIFilter(name: "CIRadialGradient") else {
            return image
        }
        
        // Position light leak at top right corner
        let center = CIVector(x: image.extent.width * 0.75, y: image.extent.height * 0.75)
        gradientFilter.setValue(center, forKey: "inputCenter")
        gradientFilter.setValue(0, forKey: "inputRadius0")
        gradientFilter.setValue(image.extent.width * 0.6, forKey: "inputRadius1")
        gradientFilter.setValue(CIColor(color: colorObj.withAlphaComponent(intensity * 0.6)), forKey: "inputColor0")
        gradientFilter.setValue(CIColor(color: .clear), forKey: "inputColor1")
        
        guard let gradientImage = gradientFilter.outputImage?.cropped(to: image.extent) else {
            return image
        }
        
        // Use lighten blend mode for more natural look
        guard let blendFilter = CIFilter(name: "CILightenBlendMode") else {
            return image
        }
        
        blendFilter.setValue(gradientImage, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Fade Effect (Improved)
    private func applyFade(to image: CIImage, amount: Double) -> CIImage {
        guard amount > 0 else { return image }
        
        // Lift blacks to create faded film look
        guard let filter = CIFilter(name: "CIColorControls") else {
            return image
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(max(0.5, 1.0 - amount * 0.4), forKey: kCIInputContrastKey)
        filter.setValue(amount * 0.15, forKey: kCIInputBrightnessKey)
        filter.setValue(max(0.7, 1.0 - amount * 0.3), forKey: kCIInputSaturationKey)
        
        return filter.outputImage ?? image
    }
    
    // MARK: - Halation (Improved)
    private func applyHalation(to image: CIImage, intensity: Double) -> CIImage {
        guard intensity > 0 else { return image }
        
        // Create glow around highlights
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return image
        }
        
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(intensity * 15, forKey: kCIInputRadiusKey)
        
        guard let blurred = blurFilter.outputImage?.cropped(to: image.extent) else {
            return image
        }
        
        // Blend softly with screen mode
        guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else {
            return image
        }
        
        // Reduce intensity of the blur
        guard let dimFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        dimFilter.setValue(blurred, forKey: kCIInputImageKey)
        let dimValue = intensity * 0.3
        dimFilter.setValue(CIVector(x: dimValue, y: 0, z: 0, w: 0), forKey: "inputRVector")
        dimFilter.setValue(CIVector(x: 0, y: dimValue, z: 0, w: 0), forKey: "inputGVector")
        dimFilter.setValue(CIVector(x: 0, y: 0, z: dimValue, w: 0), forKey: "inputBVector")
        dimFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        
        guard let dimmedBlur = dimFilter.outputImage else {
            return image
        }
        
        blendFilter.setValue(dimmedBlur, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Digital Noise (Improved)
    private func applyDigitalNoise(to image: CIImage, intensity: Double) -> CIImage {
        guard intensity > 0 else { return image }
        
        // Use CINoiseReduction in reverse - add controlled noise
        guard let noiseGenerator = CIFilter(name: "CIRandomGenerator"),
              var noiseImage = noiseGenerator.outputImage else {
            return image
        }
        
        // Scale and crop noise
        noiseImage = noiseImage.transformed(by: CGAffineTransform(scaleX: 2, y: 2))
        noiseImage = noiseImage.cropped(to: image.extent)
        
        // Make noise more colorful (like digital artifacts)
        guard let colorFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        colorFilter.setValue(noiseImage, forKey: kCIInputImageKey)
        let noiseIntensity = intensity * 0.15
        colorFilter.setValue(CIVector(x: noiseIntensity, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorFilter.setValue(CIVector(x: 0, y: noiseIntensity, z: 0, w: 0), forKey: "inputGVector")
        colorFilter.setValue(CIVector(x: 0, y: 0, z: noiseIntensity, w: 0), forKey: "inputBVector")
        colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        
        guard let coloredNoise = colorFilter.outputImage else {
            return image
        }
        
        // Add to image
        guard let addFilter = CIFilter(name: "CIAdditionCompositing") else {
            return image
        }
        
        addFilter.setValue(coloredNoise, forKey: kCIInputImageKey)
        addFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return addFilter.outputImage ?? image
    }
    
    // MARK: - Date Stamp
    private func applyDateStamp(to image: CIImage, style: DateStampStyle) -> CIImage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Create text image
        let fontSize: CGFloat = style == .vintage ? 28 : 20
        let font = UIFont(name: "Courier-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
        let textColor: UIColor = style == .vintage ? UIColor.orange.withAlphaComponent(0.9) : UIColor.white.withAlphaComponent(0.85)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
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
        
        // Position stamp at bottom right
        let padding: CGFloat = 30
        let xPosition = image.extent.width - textSize.width - padding
        let yPosition = image.extent.height - textSize.height - padding
        
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

