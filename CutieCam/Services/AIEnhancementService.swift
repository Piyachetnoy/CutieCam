//
//  AIEnhancementService.swift
//  CutieCam
//
//  AI-powered photo enhancements using Core ML
//

import Foundation
import UIKit
import CoreML
import Vision
import Combine

@MainActor
class AIEnhancementService: ObservableObject {
    @Published var isProcessing = false
    @Published var enhancementProgress: Double = 0
    
    // MARK: - AI Enhancement Types
    enum EnhancementType {
        case autoEnhance
        case beautyMode
        case skinSmoothing
        case backgroundBlur
        case colorCorrection
        case denoise
    }
    
    // MARK: - Auto Enhance
    func autoEnhance(_ image: UIImage) async throws -> UIImage {
        isProcessing = true
        enhancementProgress = 0
        
        guard let ciImage = CIImage(image: image) else {
            throw AIError.invalidImage
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        // Auto Adjust
        enhancementProgress = 0.2
        let filters = outputImage.autoAdjustmentFilters()
        for filter in filters {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                outputImage = output
            }
        }
        
        // Enhance Details
        enhancementProgress = 0.5
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
            if let output = sharpenFilter.outputImage {
                outputImage = output
            }
        }
        
        // Noise Reduction
        enhancementProgress = 0.8
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseFilter.setValue(0.4, forKey: "inputSharpness")
            if let output = noiseFilter.outputImage {
                outputImage = output
            }
        }
        
        enhancementProgress = 1.0
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIError.processingFailed
        }
        
        isProcessing = false
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Beauty Mode
    func applyBeautyMode(_ image: UIImage, intensity: Double = 0.7) async throws -> UIImage {
        isProcessing = true
        
        guard let ciImage = CIImage(image: image) else {
            throw AIError.invalidImage
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        // Skin Smoothing (simulated with blur + blend)
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            blurFilter.setValue(intensity * 5, forKey: kCIInputRadiusKey)
            
            if let blurred = blurFilter.outputImage?.cropped(to: outputImage.extent) {
                // Blend original with blurred
                if let blendFilter = CIFilter(name: "CIColorControls") {
                    blendFilter.setValue(blurred, forKey: kCIInputImageKey)
                    blendFilter.setValue(intensity, forKey: kCIInputSaturationKey)
                    
                    if let blendOutput = blendFilter.outputImage {
                        // Mix with original
                        let blendImage = CIFilter(name: "CISourceOverCompositing")
                        blendImage?.setValue(blendOutput, forKey: kCIInputImageKey)
                        blendImage?.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
                        
                        if let mixed = blendImage?.outputImage {
                            outputImage = mixed
                        }
                    }
                }
            }
        }
        
        // Brighten
        if let brightenFilter = CIFilter(name: "CIColorControls") {
            brightenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            brightenFilter.setValue(intensity * 0.1, forKey: kCIInputBrightnessKey)
            brightenFilter.setValue(1.0 + intensity * 0.1, forKey: kCIInputSaturationKey)
            if let output = brightenFilter.outputImage {
                outputImage = output
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIError.processingFailed
        }
        
        isProcessing = false
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Background Blur (Portrait Mode)
    func applyBackgroundBlur(_ image: UIImage, blurAmount: Double = 20) async throws -> UIImage {
        isProcessing = true
        
        // In a real app, you would:
        // 1. Use Vision framework to detect person
        // 2. Create segmentation mask
        // 3. Blur background only
        
        // Simplified version: Blur entire image with vignette effect
        guard let ciImage = CIImage(image: image) else {
            throw AIError.invalidImage
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        // Apply depth-like blur
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            blurFilter.setValue(blurAmount, forKey: kCIInputRadiusKey)
            
            if let blurred = blurFilter.outputImage?.cropped(to: outputImage.extent) {
                // Create radial mask to protect center
                if let maskFilter = CIFilter(name: "CIRadialGradient") {
                    let center = CIVector(x: outputImage.extent.width / 2, y: outputImage.extent.height / 2)
                    maskFilter.setValue(center, forKey: "inputCenter")
                    maskFilter.setValue(outputImage.extent.width * 0.2, forKey: "inputRadius0")
                    maskFilter.setValue(outputImage.extent.width * 0.6, forKey: "inputRadius1")
                    maskFilter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: 1), forKey: "inputColor0")
                    maskFilter.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")
                    
                    if let mask = maskFilter.outputImage?.cropped(to: outputImage.extent) {
                        // Blend original and blurred using mask
                        if let blendFilter = CIFilter(name: "CIBlendWithMask") {
                            blendFilter.setValue(outputImage, forKey: kCIInputImageKey)
                            blendFilter.setValue(blurred, forKey: kCIInputBackgroundImageKey)
                            blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
                            
                            if let result = blendFilter.outputImage {
                                outputImage = result
                            }
                        }
                    }
                }
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIError.processingFailed
        }
        
        isProcessing = false
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Color Correction
    func autoColorCorrect(_ image: UIImage) async throws -> UIImage {
        isProcessing = true
        
        guard let ciImage = CIImage(image: image) else {
            throw AIError.invalidImage
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        // White Balance
        if let whiteBalanceFilter = CIFilter(name: "CITemperatureAndTint") {
            whiteBalanceFilter.setValue(outputImage, forKey: kCIInputImageKey)
            whiteBalanceFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            whiteBalanceFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
            if let output = whiteBalanceFilter.outputImage {
                outputImage = output
            }
        }
        
        // Vibrance
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(outputImage, forKey: kCIInputImageKey)
            vibranceFilter.setValue(0.3, forKey: "inputAmount")
            if let output = vibranceFilter.outputImage {
                outputImage = output
            }
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIError.processingFailed
        }
        
        isProcessing = false
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Denoise
    func denoise(_ image: UIImage, level: Double = 0.5) async throws -> UIImage {
        isProcessing = true
        
        guard let ciImage = CIImage(image: image) else {
            throw AIError.invalidImage
        }
        
        let context = CIContext()
        
        guard let noiseFilter = CIFilter(name: "CINoiseReduction") else {
            throw AIError.filterNotAvailable
        }
        
        noiseFilter.setValue(ciImage, forKey: kCIInputImageKey)
        noiseFilter.setValue(level * 0.1, forKey: "inputNoiseLevel")
        noiseFilter.setValue(0.6, forKey: "inputSharpness")
        
        guard let outputImage = noiseFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw AIError.processingFailed
        }
        
        isProcessing = false
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
    case invalidImage
    case processingFailed
    case filterNotAvailable
    case modelLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed:
            return "AI processing failed"
        case .filterNotAvailable:
            return "AI filter not available"
        case .modelLoadFailed:
            return "Failed to load AI model"
        }
    }
}

