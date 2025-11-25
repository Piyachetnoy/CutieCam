//
//  Localization.swift
//  CutieCam
//
//  Localization utilities for Thai and English
//

import Foundation

// MARK: - Localization Manager
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    var isThaiLanguage: Bool {
        currentLanguage.contains("th")
    }
    
    func string(for key: LocalizedKey) -> String {
        isThaiLanguage ? key.thai : key.english
    }
}

// MARK: - Localized Keys
enum LocalizedKey {
    // App Name
    case appName
    
    // Camera
    case camera
    case takePhoto
    case switchCamera
    case flash
    case noFilter
    case filters
    
    // Editor
    case edit
    case save
    case cancel
    case reset
    case exposure
    case contrast
    case saturation
    case grain
    case vignette
    
    // Marketplace
    case marketplace
    case trending
    case popular
    case new
    case free
    case premium
    case search
    case searchFilters
    
    // Profile
    case profile
    case photos
    case favorites
    case settings
    case upgradeNow
    case restorePurchases
    
    // Subscription
    case upgradeToPro
    case unlockPremium
    case allPremiumFilters
    case aiEnhancements
    case unlimitedExports
    case noWatermark
    case cloudSync
    case prioritySupport
    case termsOfService
    case privacyPolicy
    
    // AI Features
    case autoEnhance
    case beautyMode
    case backgroundBlur
    case colorCorrection
    case denoise
    
    // Messages
    case processing
    case saving
    case success
    case error
    case photoSaved
    case purchaseSuccess
    case purchaseFailed
    
    var english: String {
        switch self {
        case .appName: return "CutieCam"
        case .camera: return "Camera"
        case .takePhoto: return "Take Photo"
        case .switchCamera: return "Switch Camera"
        case .flash: return "Flash"
        case .noFilter: return "No Filter"
        case .filters: return "Filters"
        case .edit: return "Edit"
        case .save: return "Save"
        case .cancel: return "Cancel"
        case .reset: return "Reset"
        case .exposure: return "Exposure"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .grain: return "Film Grain"
        case .vignette: return "Vignette"
        case .marketplace: return "Marketplace"
        case .trending: return "Trending"
        case .popular: return "Popular"
        case .new: return "New"
        case .free: return "Free"
        case .premium: return "Premium"
        case .search: return "Search"
        case .searchFilters: return "Search filters..."
        case .profile: return "Profile"
        case .photos: return "Photos"
        case .favorites: return "Favorites"
        case .settings: return "Settings"
        case .upgradeNow: return "Upgrade Now"
        case .restorePurchases: return "Restore Purchases"
        case .upgradeToPro: return "Upgrade to Pro"
        case .unlockPremium: return "Unlock Premium Features"
        case .allPremiumFilters: return "All Premium Filters"
        case .aiEnhancements: return "AI Enhancements"
        case .unlimitedExports: return "Unlimited Exports"
        case .noWatermark: return "No Watermark"
        case .cloudSync: return "Cloud Sync"
        case .prioritySupport: return "Priority Support"
        case .termsOfService: return "Terms of Service"
        case .privacyPolicy: return "Privacy Policy"
        case .autoEnhance: return "Auto Enhance"
        case .beautyMode: return "Beauty Mode"
        case .backgroundBlur: return "Background Blur"
        case .colorCorrection: return "Color Correction"
        case .denoise: return "Denoise"
        case .processing: return "Processing..."
        case .saving: return "Saving..."
        case .success: return "Success!"
        case .error: return "Error"
        case .photoSaved: return "Photo saved to library"
        case .purchaseSuccess: return "Purchase successful!"
        case .purchaseFailed: return "Purchase failed"
        }
    }
    
    var thai: String {
        switch self {
        case .appName: return "CutieCam"
        case .camera: return "กล้อง"
        case .takePhoto: return "ถ่ายรูป"
        case .switchCamera: return "สลับกล้อง"
        case .flash: return "แฟลช"
        case .noFilter: return "ไม่มีฟิลเตอร์"
        case .filters: return "ฟิลเตอร์"
        case .edit: return "แก้ไข"
        case .save: return "บันทึก"
        case .cancel: return "ยกเลิก"
        case .reset: return "รีเซ็ต"
        case .exposure: return "แสง"
        case .contrast: return "คอนทราสต์"
        case .saturation: return "ความสด"
        case .grain: return "เกล็ดฟิล์ม"
        case .vignette: return "วิเนียต"
        case .marketplace: return "ตลาดฟิลเตอร์"
        case .trending: return "ยอดนิยม"
        case .popular: return "ฮิต"
        case .new: return "ใหม่"
        case .free: return "ฟรี"
        case .premium: return "พรีเมียม"
        case .search: return "ค้นหา"
        case .searchFilters: return "ค้นหาฟิลเตอร์..."
        case .profile: return "โปรไฟล์"
        case .photos: return "รูปภาพ"
        case .favorites: return "ที่ชอบ"
        case .settings: return "ตั้งค่า"
        case .upgradeNow: return "อัปเกรดเลย"
        case .restorePurchases: return "กู้คืนการซื้อ"
        case .upgradeToPro: return "อัปเกรดเป็นโปร"
        case .unlockPremium: return "ปลดล็อกฟีเจอร์พรีเมียม"
        case .allPremiumFilters: return "ฟิลเตอร์พรีเมียมทั้งหมด"
        case .aiEnhancements: return "ปรับแต่งด้วย AI"
        case .unlimitedExports: return "บันทึกไม่จำกัด"
        case .noWatermark: return "ไม่มีลายน้ำ"
        case .cloudSync: return "ซิงค์คลาวด์"
        case .prioritySupport: return "ซัพพอร์ตพิเศษ"
        case .termsOfService: return "เงื่อนไขการใช้งาน"
        case .privacyPolicy: return "นโยบายความเป็นส่วนตัว"
        case .autoEnhance: return "ปรับแต่งอัตโนมัติ"
        case .beautyMode: return "โหมดบิวตี้"
        case .backgroundBlur: return "เบลอพื้นหลัง"
        case .colorCorrection: return "ปรับสี"
        case .denoise: return "ลดสัญญาณรบกวน"
        case .processing: return "กำลังประมวลผล..."
        case .saving: return "กำลังบันทึก..."
        case .success: return "สำเร็จ!"
        case .error: return "เกิดข้อผิดพลาด"
        case .photoSaved: return "บันทึกรูปแล้ว"
        case .purchaseSuccess: return "ซื้อสำเร็จ!"
        case .purchaseFailed: return "ซื้อไม่สำเร็จ"
        }
    }
}

// MARK: - String Extension
extension String {
    func localized() -> String {
        // For simple string localization
        return NSLocalizedString(self, comment: "")
    }
}

