import SwiftUI

public enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case planning = "planning"
    case inProgress = "inProgress"
    case paused = "paused"
    case completed = "completed"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .planning: return "Planning"
        case .inProgress: return "In Progress"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }

    public var iconName: String {
        switch self {
        case .planning: return "lightbulb"
        case .inProgress: return "hammer.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .planning: return .purple
        case .inProgress: return .blue
        case .paused: return .orange
        case .completed: return .green
        }
    }
}
