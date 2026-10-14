import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: AppTab = .projects
    @State private var selectedSidebarItem: AppTab? = .projects

    enum AppTab: String, Hashable, CaseIterable {
        case projects = "Projects"
        case templates = "Templates"

        var iconName: String {
            switch self {
            case .projects: return "hammer.fill"
            case .templates: return "square.grid.2x2.fill"
            }
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad / Mac Split View
                NavigationSplitView {
                    List(AppTab.allCases, id: \.self, selection: $selectedSidebarItem) { tab in
                        Label(tab.rawValue, systemImage: tab.iconName)
                    }
                    .navigationTitle("HobbyCraft")
                } detail: {
                    switch selectedSidebarItem ?? .projects {
                    case .projects:
                        ProjectDashboardView()
                    case .templates:
                        TemplateListView()
                    }
                }
            } else {
                // iPhone Tab View
                TabView(selection: $selectedTab) {
                    ProjectDashboardView()
                        .tabItem {
                            Label(AppTab.projects.rawValue, systemImage: AppTab.projects.iconName)
                        }
                        .tag(AppTab.projects)

                    TemplateListView()
                        .tabItem {
                            Label(AppTab.templates.rawValue, systemImage: AppTab.templates.iconName)
                        }
                        .tag(AppTab.templates)
                }
            }
        }
        .task {
            DefaultTemplates.seedTemplatesIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.previewContainer)
}
