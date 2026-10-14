import Foundation

public struct HobbyStepCatalog {
    /// Default steps specific to a given hobby project type
    public static func defaultSteps(for categoryName: String) -> [String] {
        if let template = DefaultTemplates.builtIn.first(where: {
            $0.name.localizedCaseInsensitiveContains(categoryName) ||
            categoryName.localizedCaseInsensitiveContains($0.name)
        }) {
            return template.stepNames
        }
        return []
    }
}
