import SwiftUI
import SwiftData

@Model
public final class HobbyTemplate {
    public var id: UUID = UUID()
    public var name: String = ""
    public var iconName: String = "hammer.fill"
    public var colorHex: String = "#007AFF"
    public var isBuiltIn: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \TemplateStep.template)
    public var steps: [TemplateStep]? = []

    public init(
        id: UUID = UUID(),
        name: String = "",
        iconName: String = "hammer.fill",
        colorHex: String = "#007AFF",
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.steps = []
    }

    public var sortedSteps: [TemplateStep] {
        (steps ?? []).sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    public var displayColor: Color {
        Color(hex: colorHex) ?? .blue
    }
}
