//
//  PhotoEditorView.swift
//  CutieCam
//
//  Photo editor with filter adjustments
//

import SwiftUI
import Photos

struct PhotoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var filterService = FilterService()
    
    let image: UIImage
    let filter: Filter?
    
    @State private var editedImage: UIImage?
    @State private var isProcessing = false
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var errorMessage: String?
    
    @State private var currentParameters: FilterParameters
    
    init(image: UIImage, filter: Filter?) {
        self.image = image
        self.filter = filter
        _currentParameters = State(initialValue: filter?.parameters ?? .default)
        _editedImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Image Preview
                    imagePreview
                    
                    // Adjustment Controls
                    adjustmentControls
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Success!", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Photo saved to your library")
            }
        }
    }
    
    // MARK: - Image Preview
    private var imagePreview: some View {
        GeometryReader { geometry in
            if let displayImage = editedImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Adjustment Controls
    private var adjustmentControls: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Adjust Filter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color.gray)
                
                // Basic Adjustments
                Group {
                    Text("BASIC")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    AdjustmentSlider(
                        title: "露出 (Exposure)",
                        value: $currentParameters.exposure,
                        range: -1...1,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "コントラスト (Contrast)",
                        value: $currentParameters.contrast,
                        range: 0.5...1.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "彩度 (Saturation)",
                        value: $currentParameters.saturation,
                        range: 0...1.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                }
                
                Divider()
                    .background(Color.gray)
                    .padding(.vertical, 8)
                
                // Film Effects
                Group {
                    Text("FILM EFFECTS")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    AdjustmentSlider(
                        title: "フィルムグレイン (Grain)",
                        value: $currentParameters.grainIntensity,
                        range: 0...0.8,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "ビネット (Vignette)",
                        value: $currentParameters.vignette,
                        range: 0...0.8,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "フェード (Fade)",
                        value: $currentParameters.fadeAmount,
                        range: 0...0.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "ハレーション (Halation)",
                        value: $currentParameters.halation,
                        range: 0...0.6,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                }
                
                Divider()
                    .background(Color.gray)
                    .padding(.vertical, 8)
                
                // Advanced
                Group {
                    Text("ADVANCED")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    AdjustmentSlider(
                        title: "ハイライト (Highlights)",
                        value: $currentParameters.highlights,
                        range: -0.5...0.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "シャドウ (Shadows)",
                        value: $currentParameters.shadows,
                        range: -0.5...0.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                    
                    AdjustmentSlider(
                        title: "色温度 (Temperature)",
                        value: $currentParameters.temperature,
                        range: -0.5...0.5,
                        step: 0.05
                    ) {
                        applyCurrentParameters()
                    }
                }
            }
            .padding()
        }
        .frame(height: 380)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Reset Button
            Button(action: {
                resetToOriginal()
            }) {
                Text("Reset")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
            
            // Save Button
            Button(action: {
                Task {
                    await savePhoto()
                }
            }) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Save to Library")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(isSaving)
        }
        .padding()
    }
    
    // MARK: - Functions
    private func applyCurrentParameters() {
        guard !isProcessing else { return }
        
        Task {
            isProcessing = true
            
            if let originalFilter = filter {
                // Create a new filter with updated parameters
                let adjustedFilter = Filter(
                    id: originalFilter.id,
                    name: originalFilter.name,
                    nameLocalized: originalFilter.nameLocalized,
                    description: originalFilter.description,
                    thumbnailName: originalFilter.thumbnailName,
                    creatorId: originalFilter.creatorId,
                    creatorName: originalFilter.creatorName,
                    price: originalFilter.price,
                    isPremium: originalFilter.isPremium,
                    isUserGenerated: originalFilter.isUserGenerated,
                    downloads: originalFilter.downloads,
                    rating: originalFilter.rating,
                    tags: originalFilter.tags,
                    parameters: currentParameters,
                    aestheticStyle: originalFilter.aestheticStyle,
                    dateCreated: originalFilter.dateCreated
                )
                
                do {
                    let processed = try await filterService.applyFilter(adjustedFilter, to: image)
                    await MainActor.run {
                        editedImage = processed
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            
            isProcessing = false
        }
    }
    
    private func resetToOriginal() {
        currentParameters = filter?.parameters ?? .default
        editedImage = image
    }
    
    private func savePhoto() async {
        guard let imageToSave = editedImage else { return }
        
        isSaving = true
        
        do {
            try await PhotoLibraryService.shared.savePhoto(imageToSave)
            showingSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

// MARK: - Adjustment Slider
struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onEditingChanged: () -> Void
    
    init(title: String,
         value: Binding<Double>,
         range: ClosedRange<Double>,
         step: Double = 0.01,
         onEditingChanged: @escaping () -> Void) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .foregroundColor(.orange)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(.orange)
                .onChange(of: value) { _ in
                    onEditingChanged()
                }
        }
    }
}

#Preview {
    PhotoEditorView(
        image: UIImage(systemName: "photo")!,
        filter: Filter.presetFilters.first
    )
}

