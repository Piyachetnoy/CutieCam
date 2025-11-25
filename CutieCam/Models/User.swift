//
//  User.swift
//  CutieCam
//
//  User model for authentication and filter marketplace
//

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var email: String
    var profileImageURL: String?
    var bio: String?
    var isCreator: Bool
    var isPremium: Bool
    var createdFilters: [UUID] // Filter IDs
    var purchasedFilters: [UUID] // Filter IDs
    var favoriteFilters: [UUID] // Filter IDs
    var followers: Int
    var following: Int
    var totalSales: Double
    var dateJoined: Date
    
    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        email: String,
        profileImageURL: String? = nil,
        bio: String? = nil,
        isCreator: Bool = false,
        isPremium: Bool = false,
        createdFilters: [UUID] = [],
        purchasedFilters: [UUID] = [],
        favoriteFilters: [UUID] = [],
        followers: Int = 0,
        following: Int = 0,
        totalSales: Double = 0,
        dateJoined: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.isCreator = isCreator
        self.isPremium = isPremium
        self.createdFilters = createdFilters
        self.purchasedFilters = purchasedFilters
        self.favoriteFilters = favoriteFilters
        self.followers = followers
        self.following = following
        self.totalSales = totalSales
        self.dateJoined = dateJoined
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable {
    case free
    case basic
    case pro
    case creator
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .creator: return "Creator"
        }
    }
    
    var price: Double {
        switch self {
        case .free: return 0
        case .basic: return 2.99
        case .pro: return 5.99
        case .creator: return 9.99
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["Basic filters", "Limited exports", "Watermark on photos"]
        case .basic:
            return ["All free filters", "Unlimited exports", "No watermark", "HD quality"]
        case .pro:
            return ["All features", "Premium filters", "AI enhancements", "Priority support"]
        case .creator:
            return ["All Pro features", "Sell your filters", "Analytics dashboard", "Commission: 70%"]
        }
    }
}

