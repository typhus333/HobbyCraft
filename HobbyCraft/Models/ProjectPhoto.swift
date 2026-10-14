import Foundation
import SwiftData

@Model
public final class ProjectPhoto {
    public var id: UUID = UUID()
    public var timestamp: Date = Date.now
    public var caption: String = ""
    @Attribute(.externalStorage) public var photoData: Data? = nil
    @Attribute(.externalStorage) public var thumbnailData: Data? = nil
    public var project: HobbyProject?
    public var step: ProjectStep?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date.now,
        caption: String = "",
        photoData: Data? = nil,
        thumbnailData: Data? = nil,
        project: HobbyProject? = nil,
        step: ProjectStep? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.caption = caption
        self.photoData = photoData
        self.thumbnailData = thumbnailData
        self.project = project
        self.step = step
    }
}
