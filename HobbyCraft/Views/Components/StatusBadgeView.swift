import SwiftUI

public struct StatusBadgeView: View {
    public let status: ProjectStatus

    public init(status: ProjectStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption2.bold())
            Text(status.title)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .foregroundStyle(status.color)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadgeView(status: .planning)
        StatusBadgeView(status: .inProgress)
        StatusBadgeView(status: .paused)
        StatusBadgeView(status: .completed)
    }
    .padding()
}
