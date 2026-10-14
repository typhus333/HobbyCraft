import Foundation
import SwiftUI

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

public struct HobbyTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var projectTitle: String
        public var stepName: String
        public var categoryIcon: String
        public var isPaused: Bool
        public var startTime: Date
        public var accumulatedSeconds: TimeInterval

        public init(
            projectTitle: String,
            stepName: String,
            categoryIcon: String,
            isPaused: Bool,
            startTime: Date,
            accumulatedSeconds: TimeInterval
        ) {
            self.projectTitle = projectTitle
            self.stepName = stepName
            self.categoryIcon = categoryIcon
            self.isPaused = isPaused
            self.startTime = startTime
            self.accumulatedSeconds = accumulatedSeconds
        }
    }

    public var projectId: UUID
    public var stepId: UUID

    public init(projectId: UUID, stepId: UUID) {
        self.projectId = projectId
        self.stepId = stepId
    }
}
#endif

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    #if os(iOS) && canImport(ActivityKit)
    private var currentActivity: Activity<HobbyTimerAttributes>?
    #endif

    private init() {}

    public func startActivity(
        projectId: UUID,
        stepId: UUID,
        projectTitle: String,
        stepName: String,
        categoryIcon: String,
        startTime: Date
    ) {
        #if os(iOS) && canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        endActivity()

        let attributes = HobbyTimerAttributes(projectId: projectId, stepId: stepId)
        let state = HobbyTimerAttributes.ContentState(
            projectTitle: projectTitle,
            stepName: stepName,
            categoryIcon: categoryIcon,
            isPaused: false,
            startTime: startTime,
            accumulatedSeconds: 0
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            self.currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
        #endif
    }

    public func updateActivity(
        isPaused: Bool,
        accumulatedSeconds: TimeInterval,
        startTime: Date,
        projectTitle: String,
        stepName: String,
        categoryIcon: String
    ) {
        #if os(iOS) && canImport(ActivityKit)
        guard let activity = currentActivity else { return }

        let state = HobbyTimerAttributes.ContentState(
            projectTitle: projectTitle,
            stepName: stepName,
            categoryIcon: categoryIcon,
            isPaused: isPaused,
            startTime: startTime,
            accumulatedSeconds: accumulatedSeconds
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
        #endif
    }

    public func endActivity() {
        #if os(iOS) && canImport(ActivityKit)
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        #endif
    }
}
