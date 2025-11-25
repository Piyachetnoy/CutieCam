//
//  HomeView.swift
//  CutieCam
//
//  Main home view with navigation
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(0)
            
            // Filters Marketplace Tab
            FilterMarketplaceView()
                .tabItem {
                    Label("Filters", systemImage: "sparkles")
                }
                .tag(1)
            
            // Gallery Tab
            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.stack.fill")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.orange)
    }
}

#Preview {
    HomeView()
}

