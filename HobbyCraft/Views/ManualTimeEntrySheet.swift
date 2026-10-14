import SwiftUI
import SwiftData

public struct ManualTimeEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    public let step: ProjectStep
    public let project: HobbyProject

    @State private var date: Date = Date.now
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var notes: String = ""
    @State private var markCompleted: Bool = false

    public init(step: ProjectStep, project: HobbyProject) {
        self.step = step
        self.project = project
        _markCompleted = State(initialValue: step.isCompleted)
    }

    private var calculatedDuration: TimeInterval {
        TimeInterval((hours * 3600) + (minutes * 60))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Step") {
                    HStack {
                        Image(systemName: project.iconName)
                            .foregroundStyle(project.displayColor)
                        VStack(alignment: .leading) {
                            Text(step.name)
                                .font(.headline)
                            Text(project.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Time Spent") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<100) { h in
                                Text("\(h) hrs").tag(h)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #endif

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #endif
                    }
                    .frame(height: 120)
                }

                Section("Session Info") {
                    DatePicker("Date of Work", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    TextField("Session notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)

                    Toggle("Mark step as completed", isOn: $markCompleted)
                }
            }
            .navigationTitle("Log Past Work")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log Time") {
                        saveManualEntry()
                        dismiss()
                    }
                    .disabled(calculatedDuration <= 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveManualEntry() {
        guard calculatedDuration > 0 else { return }

        let session = TimeSession(
            startDate: date.addingTimeInterval(-calculatedDuration),
            endDate: date,
            duration: calculatedDuration,
            isManualEntry: true,
            notes: notes,
            step: step
        )

        modelContext.insert(session)
        if step.sessions == nil {
            step.sessions = []
        }
        step.sessions?.append(session)

        if markCompleted {
            step.isCompleted = true
            step.completedDate = date
        }

        project.lastModifiedDate = Date.now
        try? modelContext.save()
    }
}
