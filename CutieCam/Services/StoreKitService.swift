//
//  StoreKitService.swift
//  CutieCam
//
//  In-app purchase and subscription management
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitService: ObservableObject {
    @Published var subscriptions: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var premiumFilters: [Product] = []
    @Published var isLoading = false
    @Published var error: StoreError?
    
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs
    private enum ProductIdentifier {
        static let basicSubscription = "com.cutiecam.subscription.basic"
        static let proSubscription = "com.cutiecam.subscription.pro"
        static let creatorSubscription = "com.cutiecam.subscription.creator"
        static let premiumFilterPack1 = "com.cutiecam.filter.premium.pack1"
    }
    
    init() {
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        
        do {
            // Load subscriptions
            let subscriptionIDs = [
                ProductIdentifier.basicSubscription,
                ProductIdentifier.proSubscription,
                ProductIdentifier.creatorSubscription
            ]
            
            subscriptions = try await Product.products(for: subscriptionIDs)
            
            // Load premium filters
            let filterIDs = [
                ProductIdentifier.premiumFilterPack1
            ]
            
            premiumFilters = try await Product.products(for: filterIDs)
            
            // Check current subscriptions
            await updatePurchasedProducts()
        } catch {
            self.error = .loadFailed
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try await checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = .restoreFailed
        }
    }
    
    // MARK: - Check Subscription Status
    func hasActiveSubscription(tier: SubscriptionTier) async -> Bool {
        guard let subscription = subscriptions.first(where: {
            $0.id == productID(for: tier)
        }) else {
            return false
        }
        
        return purchasedSubscriptions.contains(subscription)
    }
    
    // MARK: - Private Methods
    private func updatePurchasedProducts() async {
        var purchased: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                    purchased.append(subscription)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        self.purchasedSubscriptions = purchased
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func productID(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:
            return ""
        case .basic:
            return ProductIdentifier.basicSubscription
        case .pro:
            return ProductIdentifier.proSubscription
        case .creator:
            return ProductIdentifier.creatorSubscription
        }
    }
    
    // MARK: - Subscription Info
    func subscriptionInfo(for product: Product) -> (name: String, price: String, features: [String]) {
        let price = product.displayPrice
        
        switch product.id {
        case ProductIdentifier.basicSubscription:
            return ("Basic", price, SubscriptionTier.basic.features)
        case ProductIdentifier.proSubscription:
            return ("Pro", price, SubscriptionTier.pro.features)
        case ProductIdentifier.creatorSubscription:
            return ("Creator", price, SubscriptionTier.creator.features)
        default:
            return ("Unknown", price, [])
        }
    }
}

// MARK: - Store Errors
enum StoreError: LocalizedError {
    case loadFailed
    case purchaseFailed
    case restoreFailed
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load products"
        case .purchaseFailed:
            return "Purchase failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .verificationFailed:
            return "Transaction verification failed"
        }
    }
}

