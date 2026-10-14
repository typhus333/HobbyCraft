import SwiftUI
import SwiftData

@main
struct MyApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                HobbyProject.self,
                ProjectStep.self,
                TimeSession.self,
                ProjectPhoto.self,
                HobbyTemplate.self,
                TemplateStep.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
