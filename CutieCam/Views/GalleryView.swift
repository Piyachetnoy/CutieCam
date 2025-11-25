//
//  GalleryView.swift
//  CutieCam
//
//  Gallery view for browsing saved photos
//

import SwiftUI
import Photos

struct GalleryView: View {
    @State private var photos: [UIImage] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedImage: UIImage?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if photos.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photos.indices, id: \.self) { index in
                                Image(uiImage: photos[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .onTapGesture {
                                        selectedImage = photos[index]
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: Binding(
                get: { selectedImage.map { ImageWrapper(image: $0) } },
                set: { selectedImage = $0?.image }
            )) { wrapper in
                PhotoEditorView(image: wrapper.image, filter: nil)
            }
            .task {
                await loadPhotos()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Photos Yet")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Take your first photo with CutieCam")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func loadPhotos() async {
        isLoading = true
        
        // Request photo library access
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            errorMessage = "Photo library access denied"
            isLoading = false
            return
        }
        
        // Fetch photos from library
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var loadedPhotos: [UIImage] = []
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        fetchResult.enumerateObjects { asset, _, _ in
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    loadedPhotos.append(image)
                }
            }
        }
        
        await MainActor.run {
            self.photos = loadedPhotos
            self.isLoading = false
        }
    }
}

// Helper wrapper for identifiable UIImage
struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    GalleryView()
}

