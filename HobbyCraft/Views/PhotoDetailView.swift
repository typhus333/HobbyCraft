import SwiftUI
import SwiftData

public struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    public let photo: ProjectPhoto
    @State private var showingDeleteAlert = false

    public init(photo: ProjectPhoto) {
        self.photo = photo
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    PlatformImageView(data: photo.photoData ?? photo.thumbnailData)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Metadata Overlay
                    VStack(alignment: .leading, spacing: 6) {
                        if !photo.caption.isEmpty {
                            Text(photo.caption)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }

                        HStack {
                            if let step = photo.step {
                                Label(step.name, systemImage: "arrow.right.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }

                            Spacer()

                            Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                }
            }
            .navigationTitle("Progress Photo")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(photo)
                    try? modelContext.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This photo will be permanently removed.")
            }
        }
    }
}
