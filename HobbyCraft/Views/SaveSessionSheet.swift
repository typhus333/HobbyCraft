import SwiftUI
import SwiftData

public struct SaveSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    public let step: ProjectStep
    public let project: HobbyProject
    public let elapsedSeconds: TimeInterval

    @State private var notes: String = ""
    @State private var markStepCompleted: Bool = false
    @State private var showDiscardAlert: Bool = false

    public init(step: ProjectStep, project: HobbyProject, elapsedSeconds: TimeInterval) {
        self.step = step
        self.project = project
        self.elapsedSeconds = elapsedSeconds
        _markStepCompleted = State(initialValue: step.isCompleted)
    }

    private var formattedDuration: String {
        let totalSeconds = Int(elapsedSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: project.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(project.displayColor)
                            .padding(.top, 4)

                        Text(formattedDuration)
                            .font(.system(size: 38, weight: .bold, design: .monospaced))
                            .foregroundStyle(.primary)

                        Text("\(project.title) • \(step.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Session Details") {
                    TextField("Notes & observations (e.g. 400 grit sanding done)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle(isOn: $markStepCompleted) {
                        Label("Mark step as completed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(markStepCompleted ? .green : .primary)
                    }
                }
            }
            .navigationTitle("Save Work Session")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        showDiscardAlert = true
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        TimerManager.shared.saveSession(
                            notes: notes,
                            markStepCompleted: markStepCompleted,
                            modelContext: modelContext
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Discard this session?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    TimerManager.shared.discard()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This session's tracked time will not be recorded.")
            }
        }
    }
}
