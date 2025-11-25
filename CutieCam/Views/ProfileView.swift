//
//  ProfileView.swift
//  CutieCam
//
//  User profile and settings view
//

import SwiftUI

struct ProfileView: View {
    @State private var userName = "CutieCam User"
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.orange)
                                )
                            
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Subscription Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subscription")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showingSubscription = true
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading) {
                                        Text("CutieCam Premium")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Unlock all filters and features")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Settings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "camera.fill",
                                    title: "Camera Settings",
                                    action: {}
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    icon: "photo.fill",
                                    title: "Photo Quality",
                                    action: {}
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    icon: "paintbrush.fill",
                                    title: "Filter Preferences",
                                    action: {}
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    icon: "square.and.arrow.up.fill",
                                    title: "Export Settings",
                                    action: {}
                                )
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                SettingsRow(
                                    icon: "info.circle.fill",
                                    title: "About CutieCam",
                                    action: {}
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    icon: "doc.text.fill",
                                    title: "Privacy Policy",
                                    action: {}
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                SettingsRow(
                                    icon: "doc.fill",
                                    title: "Terms of Service",
                                    action: {}
                                )
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Version Info
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.orange)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
}

