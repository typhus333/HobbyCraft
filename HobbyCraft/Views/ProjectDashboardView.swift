import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

public struct ProjectDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HobbyProject.lastModifiedDate, order: .reverse) private var allProjects: [HobbyProject]

    @State private var selectedFilter: ProjectFilter = .all
    @State private var searchText: String = ""
    @State private var showingNewProjectSheet = false

    public enum ProjectFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"

        public var id: String { rawValue }
    }

    public init() {}

    private var filteredProjects: [HobbyProject] {
        allProjects.filter { project in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = project.status != .completed
            case .completed:
                matchesFilter = project.status == .completed
            }

            if searchText.isEmpty {
                return matchesFilter
            } else {
                let query = searchText.lowercased()
                let titleMatch = project.title.lowercased().contains(query)
                let catMatch = project.categoryName.lowercased().contains(query)
                return matchesFilter && (titleMatch || catMatch)
            }
        }
    }

    private var totalSecondsTracked: TimeInterval {
        allProjects.reduce(0) { $0 + $1.totalDuration }
    }

    private var formattedTotalTime: String {
        let totalSeconds = Int(totalSecondsTracked)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary Stats Bar
                        summaryStatsView

                        // Filter Segmented Control
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(ProjectFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Projects List
                        if filteredProjects.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredProjects) { project in
                                    NavigationLink {
                                        ProjectDetailView(project: project)
                                    } label: {
                                        projectCard(for: project)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            toggleComplete(project: project)
                                        } label: {
                                            Label(project.status == .completed ? "Reopen Project" : "Mark as Completed",
                                                  systemImage: project.status == .completed ? "arrow.uturn.backward" : "checkmark.circle")
                                        }

                                        Button(role: .destructive) {
                                            delete(project: project)
                                        } label: {
                                            Label("Delete Project", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            // Bottom padding so floating timer bar doesn't overlap content
                            .padding(.bottom, 80)
                        }
                    }
                    .padding(.top, 8)
                }

                // Floating Timer Banner
                TimerBannerView()
                    .padding(.bottom, 8)
            }
            .navigationTitle("HobbyCraft")
            .searchable(text: $searchText, prompt: "Search projects or hobbies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewProjectSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectView()
            }
        }
    }

    // MARK: - Summary Stats View
    private var summaryStatsView: some View {
        HStack(spacing: 12) {
            statItem(
                title: "Time Logged",
                value: formattedTotalTime,
                icon: "clock.badge.checkmark.fill",
                color: .blue
            )

            statItem(
                title: "In Progress",
                value: "\(allProjects.filter { $0.status != .completed }.count)",
                icon: "hammer.fill",
                color: .orange
            )

            statItem(
                title: "Completed",
                value: "\(allProjects.filter { $0.status == .completed }.count)",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Spacer()
            }
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Project Card
    private func projectCard(for project: HobbyProject) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Square Photo or Icon to the Left of all information
            leadingSquareView(for: project)

            // All Information on the Right
            VStack(alignment: .leading, spacing: 6) {
                // Category & Status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.categoryName)
                            .font(.caption2.bold())
                            .foregroundStyle(project.displayColor)
                            .textCase(.uppercase)

                        Text(project.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusBadgeView(status: project.status)
                }

                // Current Step & Big Prominent Tracked Duration Badge
                HStack(alignment: .center) {
                    if let currentStep = project.currentActiveStep {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CURRENT STEP")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(.tertiary)
                            Text(currentStep.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Big Prominent Project Time Badge
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.subheadline.weight(.bold))
                        Text(project.formattedDuration)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(project.displayColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(project.displayColor.opacity(0.16))
                    .clipShape(Capsule())
                }

                // Progress Bar
                ProgressView(value: project.progressPercentage)
                    .tint(project.displayColor)

                // Step & Photo counts
                HStack {
                    Text("\(project.completedStepsCount)/\(project.totalStepsCount) steps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let photoCount = project.photos?.count, photoCount > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Label("\(photoCount)", systemImage: "photo.stack")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(Int(project.progressPercentage * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Square Photo / Icon
    private func leadingSquareView(for project: HobbyProject) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let latestPhoto = project.latestPhoto,
               let imageData = latestPhoto.thumbnailData ?? latestPhoto.photoData {
                PlatformImageView(data: imageData)
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Subtle category indicator badge on photo corner
                Image(systemName: project.iconName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(project.displayColor.opacity(0.85))
                    .clipShape(Circle())
                    .padding(4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(project.displayColor.opacity(0.15))
                    .frame(width: 92, height: 92)

                Image(systemName: project.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(project.displayColor)
                    .frame(width: 92, height: 92)
            }
        }
        .frame(width: 92, height: 92)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack.3d.up.badge.automatic")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
                .padding(.top, 40)

            Text("No Projects Found")
                .font(.title3.bold())

            Text("Track your 3D prints, miniature painting, woodworking, or craft projects step by step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingNewProjectSheet = true
            } label: {
                Label("Start New Project", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleComplete(project: HobbyProject) {
        if project.status == .completed {
            project.status = .inProgress
        } else {
            project.status = .completed
        }
        try? modelContext.save()
    }

    private func delete(project: HobbyProject) {
        if TimerManager.shared.activeProject?.id == project.id {
            TimerManager.shared.discard()
        }
        modelContext.delete(project)
        try? modelContext.save()
    }
}
