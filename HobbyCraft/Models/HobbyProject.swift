import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Model
public final class HobbyProject {
    public var id: UUID = UUID()
    public var title: String = ""
    public var projectDescription: String = ""
    public var categoryName: String = "3D Printing"
    public var iconName: String = "cube.fill"
    public var colorHex: String = "#007AFF"
    public var statusRawValue: String = ProjectStatus.inProgress.rawValue
    public var createdDate: Date = Date.now
    public var lastModifiedDate: Date = Date.now
    public var targetDueDate: Date? = nil

    @Relationship(deleteRule: .cascade, inverse: \ProjectStep.project)
    public var steps: [ProjectStep]? = []

    @Relationship(deleteRule: .cascade, inverse: \ProjectPhoto.project)
    public var photos: [ProjectPhoto]? = []

    public init(
        id: UUID = UUID(),
        title: String = "",
        projectDescription: String = "",
        categoryName: String = "3D Printing",
        iconName: String = "cube.fill",
        colorHex: String = "#007AFF",
        status: ProjectStatus = .inProgress,
        createdDate: Date = Date.now,
        lastModifiedDate: Date = Date.now,
        targetDueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.projectDescription = projectDescription
        self.categoryName = categoryName
        self.iconName = iconName
        self.colorHex = colorHex
        self.statusRawValue = status.rawValue
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.targetDueDate = targetDueDate
        self.steps = []
        self.photos = []
    }

    public var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRawValue) ?? .inProgress }
        set {
            statusRawValue = newValue.rawValue
            lastModifiedDate = Date.now
        }
    }

    public var sortedSteps: [ProjectStep] {
        (steps ?? []).sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    public var totalDuration: TimeInterval {
        (steps ?? []).reduce(0) { $0 + $1.totalStepDuration }
    }

    public var completedStepsCount: Int {
        (steps ?? []).filter { $0.isCompleted }.count
    }

    public var totalStepsCount: Int {
        steps?.count ?? 0
    }

    public var progressPercentage: Double {
        let count = totalStepsCount
        guard count > 0 else { return 0 }
        return Double(completedStepsCount) / Double(count)
    }

    public var currentActiveStep: ProjectStep? {
        sortedSteps.first(where: { !$0.isCompleted }) ?? sortedSteps.last
    }

    public var formattedDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else if totalSeconds > 0 {
            return "\(totalSeconds)s"
        } else {
            return "0m"
        }
    }

    public var displayColor: Color {
        Color(hex: colorHex) ?? .blue
    }
}

extension Color {
    public static var cardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }

    public static var subcardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.secondary.opacity(0.06)
        #endif
    }

    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    public func toHex() -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        #else
        return nil
        #endif
    }
}
