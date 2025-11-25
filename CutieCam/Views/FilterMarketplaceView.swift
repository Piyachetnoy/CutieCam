//
//  FilterMarketplaceView.swift
//  CutieCam
//
//  Marketplace for user-generated filters
//

import SwiftUI

struct FilterMarketplaceView: View {
    @StateObject private var filterService = FilterService()
    @State private var searchText = ""
    @State private var selectedCategory: FilterTag = .trending
    
    var filteredFilters: [Filter] {
        filterService.availableFilters.filter { filter in
            (searchText.isEmpty || filter.name.lowercased().contains(searchText.lowercased())) &&
            filter.tags.contains(selectedCategory)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Category Tabs
                    categoryTabs
                    
                    // Filter Grid
                    filterGrid
                }
            }
            .navigationTitle("Filter Marketplace")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search filters...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Featured Banner
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Filter.presetFilters.prefix(3)) { filter in
                        FeaturedFilterCard(filter: filter)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([FilterTag.trending, .popular, .new, .free, .premium], id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - Filter Grid
    private var filterGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredFilters) { filter in
                    FilterCard(filter: filter)
                }
            }
            .padding()
        }
    }
}

// MARK: - Featured Filter Card
struct FeaturedFilterCard: View {
    let filter: Filter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 250, height: 150)
                .overlay(
                    VStack {
                        Image(systemName: filter.aestheticStyle.icon)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(filter.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
            
            // Info
            HStack {
                if filter.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(filter.aestheticStyle.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(String(format: "%.1f", filter.rating))
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 250)
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: FilterTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 1)
                )
        }
    }
}

// MARK: - Filter Card
struct FilterCard: View {
    let filter: Filter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: filter.aestheticStyle.icon)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        if filter.isPremium {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                        }
                    }
                )
            
            // Filter Name
            Text(filter.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Stats
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(String(format: "%.1f", filter.rating))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if filter.price > 0 {
                    Text("$\(filter.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("FREE")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

#Preview {
    FilterMarketplaceView()
}

