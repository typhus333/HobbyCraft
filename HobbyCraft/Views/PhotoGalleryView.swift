import SwiftUI
import SwiftData
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

public struct PhotoGalleryView: View {
    @Environment(\.modelContext) private var modelContext

    public let project: HobbyProject

    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var pendingImageData: Data? = nil
    @State private var pendingThumbnailData: Data? = nil
    @State private var showingAddPhotoSheet = false
    @State private var caption: String = ""
    @State private var selectedStepId: UUID? = nil
    @State private var selectedPhotoForDetail: ProjectPhoto? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)
    ]

    public init(project: HobbyProject) {
        self.project = project
    }

    private var photos: [ProjectPhoto] {
        (project.photos ?? []).sorted(by: { $0.timestamp > $1.timestamp })
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress Photos")
                    .font(.headline)
                Spacer()

                PhotosPicker(
                    selection: $selectedPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Add Photo", systemImage: "camera.badge.plus")
                        .font(.subheadline.bold())
                }
            }

            if photos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No progress photos yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Capture your 3D prints, builds, and paint layers along the way.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(photos) { photo in
                        Button {
                            selectedPhotoForDetail = photo
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                PlatformImageView(data: photo.thumbnailData ?? photo.photoData)
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: 110)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                if let step = photo.step {
                                    Text(step.name)
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Capsule())
                                        .padding(6)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: selectedPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    processImage(data: data)
                }
                selectedPickerItem = nil
            }
        }
        .sheet(isPresented: $showingAddPhotoSheet) {
            NavigationStack {
                Form {
                    if let data = pendingThumbnailData {
                        Section {
                            HStack {
                                Spacer()
                                PlatformImageView(data: data)
                                    .scaledToFit()
                                    .frame(maxHeight: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Spacer()
                            }
                        }
                    }

                    Section("Caption") {
                        TextField("e.g. First coat of primer, 220 grit sanded", text: $caption)
                    }

                    Section("Attach to Step") {
                        Picker("Project Step", selection: $selectedStepId) {
                            Text("General / None").tag(UUID?.none)
                            ForEach(project.sortedSteps, id: \.id) { step in
                                Text(step.name).tag(UUID?.some(step.id))
                            }
                        }
                    }
                }
                .navigationTitle("Save Progress Photo")
                .inlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            clearPendingPhoto()
                            showingAddPhotoSheet = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            savePhoto()
                            showingAddPhotoSheet = false
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedPhotoForDetail) { photo in
            PhotoDetailView(photo: photo)
        }
    }

    private func processImage(data: Data) {
        #if canImport(UIKit)
        if let originalImage = UIImage(data: data) {
            let maxDimension: CGFloat = 1600
            let scale = min(1.0, maxDimension / max(originalImage.size.width, originalImage.size.height))
            let targetSize = CGSize(width: originalImage.size.width * scale, height: originalImage.size.height * scale)

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resizedImage = renderer.image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            self.pendingImageData = resizedImage.jpegData(compressionQuality: 0.75)

            let thumbDimension: CGFloat = 250
            let thumbScale = min(1.0, thumbDimension / max(originalImage.size.width, originalImage.size.height))
            let thumbSize = CGSize(width: originalImage.size.width * thumbScale, height: originalImage.size.height * thumbScale)
            let thumbRenderer = UIGraphicsImageRenderer(size: thumbSize)
            let thumbImage = thumbRenderer.image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: thumbSize))
            }
            self.pendingThumbnailData = thumbImage.jpegData(compressionQuality: 0.6)
        } else {
            self.pendingImageData = data
            self.pendingThumbnailData = data
        }
        #else
        self.pendingImageData = data
        self.pendingThumbnailData = data
        #endif

        showingAddPhotoSheet = true
    }

    private func savePhoto() {
        let step = project.sortedSteps.first(where: { $0.id == selectedStepId })
        let newPhoto = ProjectPhoto(
            timestamp: Date.now,
            caption: caption,
            photoData: pendingImageData,
            thumbnailData: pendingThumbnailData,
            project: project,
            step: step
        )

        modelContext.insert(newPhoto)
        if project.photos == nil {
            project.photos = []
        }
        project.photos?.append(newPhoto)
        if let step = step {
            if step.photos == nil {
                step.photos = []
            }
            step.photos?.append(newPhoto)
        }

        project.lastModifiedDate = Date.now
        try? modelContext.save()
        clearPendingPhoto()
    }

    private func clearPendingPhoto() {
        pendingImageData = nil
        pendingThumbnailData = nil
        caption = ""
        selectedStepId = nil
    }
}
