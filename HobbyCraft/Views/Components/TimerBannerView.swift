import SwiftUI
import SwiftData

public struct TimerBannerView: View {
    @Bindable var timerManager = TimerManager.shared
    @State private var showingSaveSheet = false

    public init() {}

    public var body: some View {
        if timerManager.isRunning, let project = timerManager.activeProject, let step = timerManager.activeStep {
            HStack(spacing: 12) {
                // Project Category Icon
                ZStack {
                    Circle()
                        .fill(project.displayColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: project.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(project.displayColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(step.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(timerManager.formattedElapsedTime)
                        .font(.system(.footnote, design: .monospaced, weight: .semibold))
                        .foregroundStyle(timerManager.isPaused ? .orange : .green)
                }

                Spacer()

                // Pause / Resume Button
                Button {
                    if timerManager.isPaused {
                        timerManager.resume()
                    } else {
                        timerManager.pause()
                    }
                } label: {
                    Image(systemName: timerManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(timerManager.isPaused ? .green : .orange)
                }

                // Stop & Save Button
                Button {
                    timerManager.pause()
                    showingSaveSheet = true
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThickMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)
            .sheet(isPresented: $showingSaveSheet) {
                SaveSessionSheet(
                    step: step,
                    project: project,
                    elapsedSeconds: timerManager.currentElapsedSeconds
                )
            }
        }
    }
}
