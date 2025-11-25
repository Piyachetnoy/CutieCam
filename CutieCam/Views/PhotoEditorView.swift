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
            VStack(spacing: 20) {
                // Exposure
                AdjustmentSlider(
                    title: "Exposure",
                    value: $currentParameters.exposure,
                    range: -2...2
                ) {
                    applyCurrentParameters()
                }
                
                // Contrast
                AdjustmentSlider(
                    title: "Contrast",
                    value: $currentParameters.contrast,
                    range: 0...2
                ) {
                    applyCurrentParameters()
                }
                
                // Saturation
                AdjustmentSlider(
                    title: "Saturation",
                    value: $currentParameters.saturation,
                    range: 0...2
                ) {
                    applyCurrentParameters()
                }
                
                // Grain
                AdjustmentSlider(
                    title: "Film Grain",
                    value: $currentParameters.grainIntensity,
                    range: 0...1
                ) {
                    applyCurrentParameters()
                }
                
                // Vignette
                AdjustmentSlider(
                    title: "Vignette",
                    value: $currentParameters.vignette,
                    range: 0...1
                ) {
                    applyCurrentParameters()
                }
            }
            .padding()
        }
        .frame(height: 300)
        .background(Color.gray.opacity(0.2))
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
            
            if let filter = filter {
                var adjustedFilter = filter
                adjustedFilter.parameters = currentParameters
                
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
    let onEditingChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Slider(value: $value, in: range)
                .tint(.orange)
                .onChange(of: value) { _, _ in
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

