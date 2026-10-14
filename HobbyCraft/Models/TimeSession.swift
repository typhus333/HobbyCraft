import Foundation
import SwiftData

@Model
public final class TimeSession {
    public var id: UUID = UUID()
    public var startDate: Date = Date.now
    public var endDate: Date = Date.now
    public var duration: TimeInterval = 0
    public var isManualEntry: Bool = false
    public var notes: String = ""
    public var step: ProjectStep?

    public init(
        id: UUID = UUID(),
        startDate: Date = Date.now,
        endDate: Date = Date.now,
        duration: TimeInterval? = nil,
        isManualEntry: Bool = false,
        notes: String = "",
        step: ProjectStep? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration ?? max(0, endDate.timeIntervalSince(startDate))
        self.isManualEntry = isManualEntry
        self.notes = notes
        self.step = step
    }

    public var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
