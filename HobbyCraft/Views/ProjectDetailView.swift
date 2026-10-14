import SwiftUI
import SwiftData

public struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var timerManager = TimerManager.shared

    @Bindable public var project: HobbyProject

    @State private var showingAddStepSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSaveTimerSheet = false

    public init(project: HobbyProject) {
        self.project = project
    }

    private var isTimerActiveForProject: Bool {
        timerManager.isRunning && timerManager.activeProject?.id == project.id
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard

                // Active Timer Card (if currently running for a step in this project)
                if isTimerActiveForProject, let activeStep = timerManager.activeStep {
                    activeTimerCard(for: activeStep)
                }

                // Steps Section
                stepsSection

                // Time Distribution Breakdown
                StepBreakdownView(project: project)

                // Progress Photo Gallery
                PhotoGalleryView(project: project)
            }
            .padding()
        }
        .navigationTitle(project.title)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddStepSheet) {
            AddStepSheet(categoryName: project.categoryName) { name, estimatedMinutes, notes in
                addNewStep(name: name, estimatedMinutes: estimatedMinutes, notes: notes)
            }
        }
        .alert("Delete Project?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if isTimerActiveForProject {
                    timerManager.discard()
                }
                modelContext.delete(project)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All steps, sessions, and photos for this project will be deleted.")
        }
        .sheet(isPresented: $showingSaveTimerSheet) {
            if let activeStep = timerManager.activeStep {
                SaveSessionSheet(
                    step: activeStep,
                    project: project,
                    elapsedSeconds: timerManager.currentElapsedSeconds
                )
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(project.displayColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: project.iconName)
                        .font(.system(size: 26))
                        .foregroundStyle(project.displayColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.categoryName)
                        .font(.caption.bold())
                        .foregroundStyle(project.displayColor)
                        .textCase(.uppercase)

                    Text(project.title)
                        .font(.title3.bold())

                    HStack(spacing: 6) {
                        StatusBadgeView(status: project.status)

                        Menu {
                            ForEach(ProjectStatus.allCases) { status in
                                Button {
                                    project.status = status
                                    try? modelContext.save()
                                } label: {
                                    Label(status.title, systemImage: status.iconName)
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(project.formattedDuration)
                        .font(.title2.bold().monospaced())
                        .foregroundStyle(.primary)
                    Text("Total Time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !project.projectDescription.isEmpty {
                Text(project.projectDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress Bar
            VStack(spacing: 6) {
                ProgressView(value: project.progressPercentage)
                    .tint(project.displayColor)

                HStack {
                    Text("\(project.completedStepsCount) of \(project.totalStepsCount) steps completed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(project.progressPercentage * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Active Timer Card
    private func activeTimerCard(for step: ProjectStep) -> some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(timerManager.isPaused ? Color.orange : Color.green)
                    .frame(width: 10, height: 10)

                Text(timerManager.isPaused ? "Timer Paused" : "Active Session")
                    .font(.caption.bold())
                    .foregroundStyle(timerManager.isPaused ? .orange : .green)

                Spacer()

                Text(step.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(timerManager.formattedElapsedTime)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                Button {
                    if timerManager.isPaused {
                        timerManager.resume()
                    } else {
                        timerManager.pause()
                    }
                } label: {
                    Label(timerManager.isPaused ? "Resume" : "Pause",
                          systemImage: timerManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(timerManager.isPaused ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundStyle(timerManager.isPaused ? Color.green : Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    timerManager.pause()
                    showingSaveTimerSheet = true
                } label: {
                    Label("Stop & Save", systemImage: "stop.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(timerManager.isPaused ? Color.orange.opacity(0.4) : Color.green.opacity(0.4), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Project Steps")
                    .font(.headline)
                Spacer()

                Button {
                    showingAddStepSheet = true
                } label: {
                    Label("Add Step", systemImage: "plus")
                        .font(.subheadline.bold())
                }
            }

            if project.sortedSteps.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No steps added yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Add your first step to start tracking time and progress on this project.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Button {
                        showingAddStepSheet = true
                    } label: {
                        Label("Add Step", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(project.displayColor.opacity(0.15))
                            .foregroundStyle(project.displayColor)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 4) {
                    ForEach(project.sortedSteps) { step in
                        StepRowView(step: step, project: project)
                        if step.id != project.sortedSteps.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func addNewStep(name: String, estimatedMinutes: Int?, notes: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = project.sortedSteps.count
        let step = ProjectStep(
            name: trimmed,
            orderIndex: nextIndex,
            notes: notes,
            estimatedMinutes: estimatedMinutes,
            project: project
        )
        modelContext.insert(step)
        if project.steps == nil {
            project.steps = []
        }
        project.steps?.append(step)
        project.lastModifiedDate = Date.now
        try? modelContext.save()
    }
}

// MARK: - Edit Project Sheet
struct EditProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var project: HobbyProject

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var categoryName: String = ""
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedIcon: String = "cube.fill"

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
                Section("Project Details") {
                    TextField("Title", text: $title)
                    TextField("Category", text: $categoryName)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Theme Color") {
                    HStack(spacing: 14) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    HStack(spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? .blue) : .secondary)
                                .padding(8)
                                .background(selectedIcon == icon ? Color(hex: selectedColorHex)?.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Project")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        project.title = title
                        project.projectDescription = description
                        project.categoryName = categoryName
                        project.colorHex = selectedColorHex
                        project.iconName = selectedIcon
                        project.lastModifiedDate = Date.now
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                title = project.title
                description = project.projectDescription
                categoryName = project.categoryName
                selectedColorHex = project.colorHex
                selectedIcon = project.iconName
            }
        }
    }
}
