//
//  SubscriptionView.swift
//  CutieCam
//
//  Subscription purchase view
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var storeService = StoreKitService()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Features
                        featuresSection
                        
                        // Subscription Plans
                        if storeService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            subscriptionPlans
                        }
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Restore Button
                        restoreButton
                        
                        // Terms
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .task {
                await storeService.loadProducts()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Unlock Premium Features")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Get unlimited access to all filters and AI enhancements")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "camera.filters", title: "All Premium Filters", description: "Access 100+ exclusive filters")
            FeatureRow(icon: "wand.and.stars", title: "AI Enhancements", description: "Auto beauty mode & background blur")
            FeatureRow(icon: "photo.stack", title: "Unlimited Exports", description: "Save unlimited photos in HD")
            FeatureRow(icon: "xmark.seal", title: "No Watermark", description: "Export clean, professional photos")
            FeatureRow(icon: "arrow.clockwise", title: "Cloud Sync", description: "Sync filters across devices")
            FeatureRow(icon: "person.2", title: "Priority Support", description: "Get help when you need it")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
    
    // MARK: - Subscription Plans
    private var subscriptionPlans: some View {
        VStack(spacing: 12) {
            ForEach(storeService.subscriptions, id: \.id) { product in
                SubscriptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isPurchased: storeService.purchasedSubscriptions.contains(where: { $0.id == product.id }),
                    storeService: storeService
                ) {
                    selectedProduct = product
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchaseSelected()
            }
        }) {
            if isPurchasing {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await storeService.restorePurchases()
            }
        }
        .font(.subheadline)
        .foregroundColor(.gray)
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Auto-renewable subscription")
                .font(.caption2)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                Button("Terms of Service") {}
                Button("Privacy Policy") {}
            }
            .font(.caption2)
            .foregroundColor(.blue)
        }
        .padding(.top)
    }
    
    // MARK: - Purchase Action
    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        do {
            _ = try await storeService.purchase(product)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isPurchasing = false
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Card
struct SubscriptionCard: View {
    let product: Product
    let isSelected: Bool
    let isPurchased: Bool
    let storeService: StoreKitService
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            let info = storeService.subscriptionInfo(for: product)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(info.price + "/month")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(info.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    SubscriptionView()
}

