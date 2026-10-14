import SwiftUI

public struct StepBreakdownView: View {
    public let project: HobbyProject

    public init(project: HobbyProject) {
        self.project = project
    }

    public var body: some View {
        let total = project.totalDuration

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Time Distribution")
                    .font(.headline)
                Spacer()
                Text("Total: \(project.formattedDuration)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if total <= 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No time tracked yet")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(project.sortedSteps) { step in
                        let stepDuration = step.totalStepDuration
                        let percentage = total > 0 ? (stepDuration / total) : 0

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(step.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(step.formattedDuration)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                                Text("(\(Int(percentage * 100))%)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.tertiary)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(step.isCompleted ? Color.green : project.displayColor)
                                        .frame(width: max(4, geo.size.width * CGFloat(percentage)), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
