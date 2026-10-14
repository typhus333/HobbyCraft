import SwiftUI
import SwiftData

public struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var templates: [HobbyTemplate]

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTemplateIndex: Int = 0
    @State private var categoryName: String = "3D Printing"
    @State private var iconName: String = "cube.fill"
    @State private var colorHex: String = "#007AFF"
    @State private var status: ProjectStatus = .inProgress
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date.now.addingTimeInterval(86400 * 14)

    // New projects start with NO steps by default
    @State private var steps: [String] = []
    @State private var showingAddStepSheet = false

    private let availableIcons = [
        "cube.fill", "paintbrush.fill", "hammer.fill", "airplane", "scissors",
        "wand.and.stars", "wrench.and.screwdriver.fill", "camera.fill", "car.fill"
    ]

    private let availableColors = [
        "#007AFF", "#AF52DE", "#FF9500", "#34C759", "#FF2D55", "#5856D6", "#FFCC00"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Category / Preset Selection (sets icon & color theme, but does NOT add default steps)
                Section("Hobby Category") {
                    Picker("Category", selection: $selectedTemplateIndex) {
                        ForEach(0..<DefaultTemplates.builtIn.count, id: \.self) { index in
                            let template = DefaultTemplates.builtIn[index]
                            Label(template.name, systemImage: template.icon).tag(index)
                        }
                        Text("Custom").tag(DefaultTemplates.builtIn.count)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTemplateIndex) { _, newIndex in
                        applySelectedTemplate(at: newIndex)
                    }
                }

                // Basic Details
                Section("Project Details") {
                    TextField("Project Title (e.g. Iron Man Helmet)", text: $title)
                    TextField("Category Name", text: $categoryName)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Theme & Icon
                Section("Color & Icon") {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    colorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 14) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(iconName == icon ? (Color(hex: colorHex) ?? .blue) : .secondary)
                                .padding(6)
                                .background(iconName == icon ? (Color(hex: colorHex)?.opacity(0.15) ?? .clear) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    iconName = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Target Due Date
                Section("Deadline") {
                    Toggle("Set target completion date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Target Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                // Optional Steps List (Starts with 0 steps; user can choose to add steps with dropdown)
                Section {
                    if steps.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No steps added yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("This project will start with no steps. You can add steps as you work from the project screen using the step type dropdown.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(steps.indices, id: \.self) { index in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.secondary)
                                Text(steps[index])
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteSteps)
                        .onMove(perform: moveSteps)
                    }

                    Button {
                        showingAddStepSheet = true
                    } label: {
                        Label("Add Step...", systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                } header: {
                    Text("Project Steps (\(steps.count))")
                }
            }
            .navigationTitle("New Project")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }

                #if os(iOS)
                if !steps.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddStepSheet) {
                AddStepSheet(categoryName: categoryName) { newName, _, _ in
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        steps.append(trimmed)
                    }
                }
            }
            .onAppear {
                applySelectedTemplate(at: 0)
            }
        }
    }

    private func applySelectedTemplate(at index: Int) {
        if index < DefaultTemplates.builtIn.count {
            let template = DefaultTemplates.builtIn[index]
            categoryName = template.name
            iconName = template.icon
            colorHex = template.colorHex
            // NOTE: We deliberately do NOT populate `steps` with default steps!
        } else {
            categoryName = "Custom"
            iconName = "hammer.fill"
            colorHex = "#FF9500"
        }
    }

    private func deleteSteps(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
    }

    private func createProject() {
        let newProject = HobbyProject(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            projectDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryName: categoryName,
            iconName: iconName,
            colorHex: colorHex,
            status: status,
            targetDueDate: hasDueDate ? dueDate : nil
        )

        modelContext.insert(newProject)

        var projectSteps: [ProjectStep] = []
        for (index, stepName) in steps.enumerated() {
            let step = ProjectStep(
                name: stepName,
                orderIndex: index,
                project: newProject
            )
            modelContext.insert(step)
            projectSteps.append(step)
        }
        newProject.steps = projectSteps

        try? modelContext.save()
    }
}
