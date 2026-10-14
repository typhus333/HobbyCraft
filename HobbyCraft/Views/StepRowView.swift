import SwiftUI
import SwiftData

public struct StepRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var timerManager = TimerManager.shared

    public let step: ProjectStep
    public let project: HobbyProject

    @State private var showingManualLog = false
    @State private var showingSessionsList = false
    @State private var isExpanded = false

    public init(step: ProjectStep, project: HobbyProject) {
        self.step = step
        self.project = project
    }

    private var isCurrentActiveTimer: Bool {
        timerManager.isRunning && timerManager.activeStep?.id == step.id
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Step completion button
                Button {
                    step.isCompleted.toggle()
                    step.completedDate = step.isCompleted ? Date.now : nil
                    project.lastModifiedDate = Date.now
                    try? modelContext.save()
                } label: {
                    Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(step.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // Step Name & Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("\(step.orderIndex + 1).")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text(step.name)
                            .font(.subheadline.weight(.semibold))
                            .strikethrough(step.isCompleted, color: .secondary)
                            .foregroundStyle(step.isCompleted ? .secondary : .primary)
                    }

                    HStack(spacing: 8) {
                        Label(step.formattedDuration, systemImage: "clock")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)

                        if let sessionsCount = step.sessions?.count, sessionsCount > 0 {
                            Text("• \(sessionsCount) \(sessionsCount == 1 ? "session" : "sessions")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                // Actions: Timer Button & Manual Entry
                HStack(spacing: 8) {
                    // Manual Time Entry Button
                    Button {
                        showingManualLog = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Timer Start / Pause Button
                    Button {
                        if isCurrentActiveTimer {
                            if timerManager.isPaused {
                                timerManager.resume()
                            } else {
                                timerManager.pause()
                            }
                        } else {
                            timerManager.start(project: project, step: step)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isCurrentActiveTimer ? (timerManager.isPaused ? Color.orange : Color.green) : project.displayColor.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: isCurrentActiveTimer ? (timerManager.isPaused ? "play.fill" : "pause.fill") : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isCurrentActiveTimer ? .white : project.displayColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Expanded Sessions Details
            if let sessions = step.sessions, !sessions.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Hide sessions" : "View \(sessions.count) logged \(sessions.count == 1 ? "session" : "sessions")")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 34)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(sessions.sorted(by: { $0.endDate > $1.endDate })) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.formattedDuration)
                                        .font(.caption.bold())
                                    if !session.notes.isEmpty {
                                        Text(session.notes)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(session.endDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(8)
                            .background(Color.subcardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.leading, 34)
                }
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showingManualLog) {
            ManualTimeEntrySheet(step: step, project: project)
        }
    }
}
