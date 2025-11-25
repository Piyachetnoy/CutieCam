//
//  CameraView.swift
//  CutieCam
//
//  Main camera view with film aesthetic
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(session: viewModel.cameraService.session)
                .ignoresSafeArea()
            
            // Camera UI Overlay
            VStack {
                // Top Bar
                topBar
                
                Spacer()
                
                // Filter Selector
                if viewModel.showingFilterSelector {
                    filterSelector
                        .transition(.move(edge: .bottom))
                }
                
                // Bottom Controls
                bottomControls
            }
            .padding()
            
            // Loading Indicator
            if viewModel.isCapturing || viewModel.filterService.isProcessing {
                LoadingView()
            }
        }
        .task {
            await viewModel.setupCamera()
        }
        .sheet(isPresented: $viewModel.showingEditor) {
            if let image = viewModel.processedImage {
                PhotoEditorView(image: image, filter: viewModel.selectedFilter)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Flash Toggle
            Button(action: {
                viewModel.toggleFlash()
            }) {
                Image(systemName: viewModel.cameraService.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // App Title
            Text("CutieCam")
                .font(.custom("Courier", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Spacer()
            
            // Settings
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Filter Selector
    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // No Filter Option
                FilterThumbnailView(
                    filter: nil,
                    isSelected: viewModel.selectedFilter == nil
                ) {
                    viewModel.selectFilter(nil)
                }
                
                // Available Filters
                ForEach(viewModel.filterService.availableFilters) { filter in
                    FilterThumbnailView(
                        filter: filter,
                        isSelected: viewModel.selectedFilter?.id == filter.id
                    ) {
                        viewModel.selectFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 100)
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
        HStack(spacing: 40) {
            // Gallery
            Button(action: {
                // TODO: Open gallery
            }) {
                Image(systemName: "photo.stack.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Capture Button
            Button(action: {
                Task {
                    await viewModel.capturePhoto()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                }
            }
            .disabled(viewModel.isCapturing)
            
            // Switch Camera
            Button(action: {
                Task {
                    await viewModel.switchCamera()
                }
            }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 20)
        
        // Filter Toggle
        Button(action: {
            withAnimation {
                viewModel.showingFilterSelector.toggle()
            }
        }) {
            HStack {
                Image(systemName: "camera.filters")
                Text(viewModel.selectedFilter?.name ?? "No Filter")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
        }
        .padding(.bottom, 10)
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Filter Thumbnail View
struct FilterThumbnailView: View {
    let filter: Filter?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(filter == nil ? Color.gray : Color.orange)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(filter == nil ? "None" : String(filter!.name.prefix(1)))
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                
                // Filter Name
                Text(filter?.name ?? "None")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    CameraView()
}

