import Foundation
import SwiftData

@Model
public final class TemplateStep {
    public var id: UUID = UUID()
    public var name: String = ""
    public var orderIndex: Int = 0
    public var defaultEstimatedMinutes: Int? = nil
    public var template: HobbyTemplate?

    public init(
        id: UUID = UUID(),
        name: String = "",
        orderIndex: Int = 0,
        defaultEstimatedMinutes: Int? = nil,
        template: HobbyTemplate? = nil
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.defaultEstimatedMinutes = defaultEstimatedMinutes
        self.template = template
    }
}
