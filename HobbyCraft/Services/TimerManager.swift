import SwiftUI
import SwiftData

@Observable
@MainActor
public final class TimerManager {
    public static let shared = TimerManager()

    public var activeProject: HobbyProject?
    public var activeStep: ProjectStep?
    public var isRunning: Bool = false
    public var isPaused: Bool = false
    public var startTime: Date?
    public var accumulatedTime: TimeInterval = 0

    // For UI binding and live updates
    public var currentElapsedSeconds: TimeInterval = 0

    private var tickerTask: Task<Void, Never>?

    public init() {}

    public var formattedElapsedTime: String {
        let totalSeconds = Int(currentElapsedSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public func start(project: HobbyProject, step: ProjectStep) {
        if isRunning {
            // If already running for this exact step, do nothing
            if activeStep?.id == step.id {
                if isPaused {
                    resume()
                }
                return
            }
            // Stop previous before starting new
            _ = stop()
        }

        activeProject = project
        activeStep = step
        isRunning = true
        isPaused = false
        startTime = Date.now
        accumulatedTime = 0
        currentElapsedSeconds = 0

        startTicker()

        LiveActivityManager.shared.startActivity(
            projectId: project.id,
            stepId: step.id,
            projectTitle: project.title,
            stepName: step.name,
            categoryIcon: project.iconName,
            startTime: Date.now
        )
    }

    public func pause() {
        guard isRunning, !isPaused, let start = startTime else { return }
        accumulatedTime += Date.now.timeIntervalSince(start)
        startTime = nil
        isPaused = true
        currentElapsedSeconds = accumulatedTime

        if let project = activeProject, let step = activeStep {
            LiveActivityManager.shared.updateActivity(
                isPaused: true,
                accumulatedSeconds: accumulatedTime,
                startTime: Date.now,
                projectTitle: project.title,
                stepName: step.name,
                categoryIcon: project.iconName
            )
        }
    }

    public func resume() {
        guard isRunning, isPaused else { return }
        startTime = Date.now
        isPaused = false

        if let project = activeProject, let step = activeStep {
            LiveActivityManager.shared.updateActivity(
                isPaused: false,
                accumulatedSeconds: accumulatedTime,
                startTime: Date.now,
                projectTitle: project.title,
                stepName: step.name,
                categoryIcon: project.iconName
            )
        }
    }

    @discardableResult
    public func stop() -> TimeInterval {
        if !isPaused, let start = startTime {
            accumulatedTime += Date.now.timeIntervalSince(start)
        }
        let totalDuration = accumulatedTime

        tickerTask?.cancel()
        tickerTask = nil

        LiveActivityManager.shared.endActivity()

        isRunning = false
        isPaused = false
        startTime = nil
        currentElapsedSeconds = totalDuration

        return totalDuration
    }

    public func discard() {
        tickerTask?.cancel()
        tickerTask = nil
        LiveActivityManager.shared.endActivity()

        isRunning = false
        isPaused = false
        startTime = nil
        accumulatedTime = 0
        currentElapsedSeconds = 0
        activeStep = nil
        activeProject = nil
    }

    public func saveSession(
        notes: String,
        markStepCompleted: Bool,
        modelContext: ModelContext
    ) {
        guard let step = activeStep else { return }
        let duration = stop()
        guard duration > 0 else {
            discard()
            return
        }

        let session = TimeSession(
            startDate: Date.now.addingTimeInterval(-duration),
            endDate: Date.now,
            duration: duration,
            isManualEntry: false,
            notes: notes,
            step: step
        )

        modelContext.insert(session)
        if step.sessions == nil {
            step.sessions = []
        }
        step.sessions?.append(session)

        if markStepCompleted {
            step.isCompleted = true
            step.completedDate = Date.now
        }

        if let project = activeProject {
            project.lastModifiedDate = Date.now
        }

        try? modelContext.save()

        discard()
    }

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s updates
                guard let self = self, self.isRunning else { break }
                if !self.isPaused, let start = self.startTime {
                    self.currentElapsedSeconds = self.accumulatedTime + Date.now.timeIntervalSince(start)
                }
            }
        }
    }
}
