import Foundation
import SwiftData

@Model
public final class ProjectStep: Identifiable {
    public var id: UUID = UUID()
    public var name: String = ""
    public var orderIndex: Int = 0
    public var isCompleted: Bool = false
    public var completedDate: Date? = nil
    public var notes: String = ""
    public var estimatedMinutes: Int? = nil

    public var project: HobbyProject?
    @Relationship(deleteRule: .cascade, inverse: \TimeSession.step)
    public var sessions: [TimeSession]? = []
    @Relationship(inverse: \ProjectPhoto.step)
    public var photos: [ProjectPhoto]? = []

    public init(
        id: UUID = UUID(),
        name: String = "",
        orderIndex: Int = 0,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        notes: String = "",
        estimatedMinutes: Int? = nil,
        project: HobbyProject? = nil
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.notes = notes
        self.estimatedMinutes = estimatedMinutes
        self.project = project
        self.sessions = []
        self.photos = []
    }

    public var totalStepDuration: TimeInterval {
        (sessions ?? []).reduce(0) { $0 + $1.duration }
    }

    public var formattedDuration: String {
        let totalSeconds = Int(totalStepDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else if totalSeconds > 0 {
            return String(format: "%ds", seconds)
        } else {
            return "0m"
        }
    }
}
