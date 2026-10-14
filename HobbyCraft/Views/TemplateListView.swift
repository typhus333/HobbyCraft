import SwiftUI
import SwiftData

public struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HobbyTemplate.name) private var templates: [HobbyTemplate]

    @State private var showingAddTemplateSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Hobby Workflows") {
                    ForEach(templates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(template.displayColor.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: template.iconName)
                                        .foregroundStyle(template.displayColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text("\(template.steps?.count ?? 0) default steps")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if template.isBuiltIn {
                                    Text("Preset")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
            .navigationTitle("Hobby Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTemplateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplateSheet) {
                AddTemplateSheet()
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = templates[index]
            if !template.isBuiltIn {
                modelContext.delete(template)
            }
        }
        try? modelContext.save()
    }
}

// MARK: - Template Detail View
struct TemplateDetailView: View {
    let template: HobbyTemplate

    var body: some View {
        List {
            Section("Workflow Steps") {
                ForEach(template.sortedSteps) { step in
                    HStack {
                        Text("\(step.orderIndex + 1).")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(step.name)
                            .font(.body)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(template.name)
    }
}

// MARK: - Add Template Sheet
struct AddTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var iconName: String = "hammer.fill"
    @State private var colorHex: String = "#FF9500"
    @State private var steps: [String] = []
    @State private var newStepInput: String = ""

    private let availableIcons = [
        "cube.fill", "paintbrush.fill", "hammer.fill", "airplane", "scissors",
        "wand.and.stars", "wrench.and.screwdriver.fill", "camera.fill", "car.fill"
    ]

    private let availableColors = [
        "#007AFF", "#AF52DE", "#FF9500", "#34C759", "#FF2D55", "#5856D6", "#FFCC00"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Template Name (e.g. Leathercraft)", text: $name)
                }

                Section("Theme Color & Icon") {
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

                Section("Default Steps (\(steps.count))") {
                    ForEach(steps.indices, id: \.self) { idx in
                        Text("\(idx + 1). \(steps[idx])")
                    }
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                    }

                    HStack {
                        TextField("New step name", text: $newStepInput)
                        Button("Add") {
                            let trimmed = newStepInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                steps.append(trimmed)
                                newStepInput = ""
                            }
                        }
                        .disabled(newStepInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("New Template")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        createTemplate()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createTemplate() {
        let template = HobbyTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName,
            colorHex: colorHex,
            isBuiltIn: false
        )
        modelContext.insert(template)

        var templateSteps: [TemplateStep] = []
        for (index, stepName) in steps.enumerated() {
            let step = TemplateStep(
                name: stepName,
                orderIndex: index,
                template: template
            )
            modelContext.insert(step)
            templateSteps.append(step)
        }
        template.steps = templateSteps
        try? modelContext.save()
    }
}
