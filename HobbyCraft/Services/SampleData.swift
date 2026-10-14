import SwiftUI
import SwiftData

public struct DefaultTemplates {
    public struct TemplateDefinition {
        public let name: String
        public let icon: String
        public let colorHex: String
        public let stepNames: [String]
    }

    public static let builtIn: [TemplateDefinition] = [
        TemplateDefinition(
            name: "3D Printing",
            icon: "cube.fill",
            colorHex: "#007AFF",
            stepNames: [
                "CAD Design & Slicing",
                "Machine Printing",
                "Support Removal & Wash",
                "Sanding & Surface Prep",
                "Priming & Painting",
                "Clear Coat & Assembly"
            ]
        ),
        TemplateDefinition(
            name: "Miniature Painting",
            icon: "paintbrush.fill",
            colorHex: "#AF52DE",
            stepNames: [
                "Assembly & Gap Filling",
                "Priming & Pre-shading",
                "Basecoating",
                "Shading & Washing",
                "Layering & Highlights",
                "Basing & Varnishing"
            ]
        ),
        TemplateDefinition(
            name: "Woodworking",
            icon: "hammer.fill",
            colorHex: "#FF9500",
            stepNames: [
                "Design & Stock Selection",
                "Milling & Dimensioning",
                "Joinery & Cutting",
                "Dry Fit & Adjustments",
                "Glue-Up & Clamping",
                "Sanding & Prep",
                "Finishing & Hardware"
            ]
        ),
        TemplateDefinition(
            name: "Scale Modeling",
            icon: "airplane",
            colorHex: "#34C759",
            stepNames: [
                "Parts Prep & Sub-assembly",
                "Cockpit / Interior Detailing",
                "Main Assembly & Gap Filling",
                "Priming",
                "Base Painting & Camo",
                "Decals & Weathering",
                "Final Clear Coat"
            ]
        )
    ]

    @MainActor
    public static func seedTemplatesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<HobbyTemplate>()
        if let count = try? context.fetchCount(descriptor), count == 0 {
            for def in builtIn {
                let template = HobbyTemplate(
                    name: def.name,
                    iconName: def.icon,
                    colorHex: def.colorHex,
                    isBuiltIn: true
                )
                context.insert(template)

                var steps: [TemplateStep] = []
                for (index, name) in def.stepNames.enumerated() {
                    let step = TemplateStep(
                        name: name,
                        orderIndex: index,
                        defaultEstimatedMinutes: 60,
                        template: template
                    )
                    context.insert(step)
                    steps.append(step)
                }
                template.steps = steps
            }
            try? context.save()
        }
    }
}

@MainActor
public struct PreviewSampleData {
    public static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: HobbyProject.self,
                ProjectStep.self,
                TimeSession.self,
                ProjectPhoto.self,
                HobbyTemplate.self,
                TemplateStep.self,
                configurations: config
            )
            let context = container.mainContext

            // Seed templates
            DefaultTemplates.seedTemplatesIfNeeded(context: context)

            // Seed a sample project
            let project = HobbyProject(
                title: "Cyberpunk Diorama",
                projectDescription: "A futuristic night alleyway diorama with LED signage and resin puddle effects.",
                categoryName: "3D Printing",
                iconName: "cube.fill",
                colorHex: "#007AFF",
                status: .inProgress,
                createdDate: Date.now.addingTimeInterval(-86400 * 3)
            )
            context.insert(project)

            let step1 = ProjectStep(
                name: "CAD Modeling & Slicing",
                orderIndex: 0,
                isCompleted: true,
                completedDate: Date.now.addingTimeInterval(-86400 * 2),
                notes: "Oriented buildings at 45 degrees to minimize support marks.",
                project: project
            )
            let step2 = ProjectStep(
                name: "Resin Printing",
                orderIndex: 1,
                isCompleted: true,
                completedDate: Date.now.addingTimeInterval(-86400 * 1),
                notes: "Printed at 0.03mm layer height.",
                project: project
            )
            let step3 = ProjectStep(
                name: "Sanding & Wash",
                orderIndex: 2,
                isCompleted: false,
                notes: "Wet sanding with 600 grit.",
                project: project
            )
            let step4 = ProjectStep(
                name: "Airbrushing & Weathering",
                orderIndex: 3,
                isCompleted: false,
                notes: "Neon magenta and cyan accents.",
                project: project
            )

            context.insert(step1)
            context.insert(step2)
            context.insert(step3)
            context.insert(step4)

            // Sessions
            let session1 = TimeSession(
                startDate: Date.now.addingTimeInterval(-86400 * 2),
                endDate: Date.now.addingTimeInterval(-86400 * 2 + 5400),
                duration: 5400,
                notes: "Finished slicing building structures",
                step: step1
            )
            let session2 = TimeSession(
                startDate: Date.now.addingTimeInterval(-86400),
                endDate: Date.now.addingTimeInterval(-86400 + 10800),
                duration: 10800,
                notes: "Full resin print run",
                step: step2
            )
            let session3 = TimeSession(
                startDate: Date.now.addingTimeInterval(-3600),
                endDate: Date.now,
                duration: 3600,
                notes: "Initial wash and cure station",
                step: step3
            )

            context.insert(session1)
            context.insert(session2)
            context.insert(session3)

            step1.sessions = [session1]
            step2.sessions = [session2]
            step3.sessions = [session3]
            step4.sessions = []

            project.steps = [step1, step2, step3, step4]

            try? context.save()
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}
