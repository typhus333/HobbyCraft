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

    @State private var steps: [String] = []
    @State private var newStepInput: String = ""

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
                // Template Selection
                Section("Choose Hobby Template") {
                    Picker("Template", selection: $selectedTemplateIndex) {
                        ForEach(0..<DefaultTemplates.builtIn.count, id: \.self) { index in
                            let template = DefaultTemplates.builtIn[index]
                            Label(template.name, systemImage: template.icon).tag(index)
                        }
                        Text("Custom (Blank)").tag(DefaultTemplates.builtIn.count)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTemplateIndex) { _, newIndex in
                        applySelectedTemplate(at: newIndex)
                    }
                }

                // Basic Details
                Section("Project Details") {
                    TextField("Project Title (e.g. Iron Man Helmet)", text: $title)
                    TextField("Category", text: $categoryName)
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

                // Process Steps
                Section("Project Steps (\(steps.count))") {
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

                    HStack {
                        TextField("Add custom step", text: $newStepInput)
                        Button("Add") {
                            addCustomStep()
                        }
                        .disabled(newStepInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
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
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                #endif
            }
            .onAppear {
                if steps.isEmpty {
                    applySelectedTemplate(at: 0)
                }
            }
        }
    }

    private func applySelectedTemplate(at index: Int) {
        if index < DefaultTemplates.builtIn.count {
            let template = DefaultTemplates.builtIn[index]
            categoryName = template.name
            iconName = template.icon
            colorHex = template.colorHex
            steps = template.stepNames
        } else {
            categoryName = "Custom"
            iconName = "hammer.fill"
            colorHex = "#FF9500"
            steps = ["Design & Prep", "Execution", "Finishing"]
        }
    }

    private func addCustomStep() {
        let trimmed = newStepInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        steps.append(trimmed)
        newStepInput = ""
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
