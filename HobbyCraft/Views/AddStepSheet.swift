import SwiftUI
import SwiftData

public struct AddStepSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var templates: [HobbyTemplate]

    public let categoryName: String
    public let onAdd: (String, Int?, String) -> Void

    @State private var selectedChoice: String = ""
    @State private var customStepName: String = ""
    @State private var hasEstimate: Bool = false
    @State private var estimateHours: Int = 1
    @State private var estimateMins: Int = 0
    @State private var notes: String = ""

    private let customOptionKey = "__custom__"

    public init(categoryName: String, onAdd: @escaping (String, Int?, String) -> Void) {
        self.categoryName = categoryName
        self.onAdd = onAdd
    }

    /// Only the default steps for the parent project type
    private var defaultStepsForProjectType: [String] {
        if let customMatch = templates.first(where: {
            $0.name.localizedCaseInsensitiveContains(categoryName) ||
            categoryName.localizedCaseInsensitiveContains($0.name)
        }), let steps = customMatch.steps, !steps.isEmpty {
            return customMatch.sortedSteps.map { $0.name }
        }
        return HobbyStepCatalog.defaultSteps(for: categoryName)
    }

    private var finalStepName: String {
        if selectedChoice == customOptionKey {
            return customStepName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return customStepName.isEmpty ? selectedChoice : customStepName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Dropdown showing ONLY parent project type's default steps + Custom Step
                Section("Type of Step") {
                    Picker("Step Type", selection: $selectedChoice) {
                        ForEach(defaultStepsForProjectType, id: \.self) { step in
                            Text(step).tag(step)
                        }

                        if !defaultStepsForProjectType.isEmpty {
                            Divider()
                        }

                        Text("Custom Step...").tag(customOptionKey)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedChoice) { _, newChoice in
                        if newChoice == customOptionKey {
                            if customStepName == selectedChoice {
                                customStepName = ""
                            }
                        } else if !newChoice.isEmpty {
                            customStepName = newChoice
                        }
                    }
                }

                // Step Name field (auto-filled by dropdown choice or custom typed)
                Section("Step Name") {
                    TextField(selectedChoice == customOptionKey ? "Enter custom step name" : "Step Name", text: $customStepName)

                    if selectedChoice == customOptionKey && customStepName.isEmpty {
                        Text("Enter a unique name for this custom step.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Optional Estimated Time
                Section("Estimated Duration (Optional)") {
                    Toggle("Set estimated time", isOn: $hasEstimate)
                    if hasEstimate {
                        HStack {
                            Picker("Hours", selection: $estimateHours) {
                                ForEach(0..<50) { h in
                                    Text("\(h) h").tag(h)
                                }
                            }
                            #if os(iOS)
                            .pickerStyle(.wheel)
                            #endif

                            Picker("Minutes", selection: $estimateMins) {
                                ForEach([0, 15, 30, 45], id: \.self) { m in
                                    Text("\(m) m").tag(m)
                                }
                            }
                            #if os(iOS)
                            .pickerStyle(.wheel)
                            #endif
                        }
                        .frame(height: 100)
                    }
                }

                // Optional Notes
                Section("Notes (Optional)") {
                    TextField("Step instructions, checklist, or materials...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Project Step")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let totalMins = hasEstimate ? (estimateHours * 60 + estimateMins) : nil
                        onAdd(finalStepName, totalMins, notes)
                        dismiss()
                    }
                    .disabled(finalStepName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let first = defaultStepsForProjectType.first {
                    selectedChoice = first
                    customStepName = first
                } else {
                    selectedChoice = customOptionKey
                    customStepName = ""
                }
            }
        }
    }
}
