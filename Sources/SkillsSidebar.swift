import SwiftUI

struct SkillsSidebar: View {
    @Environment(SkillsManager.self) private var manager
    @Binding var selectedSkillID: Skill.ID?
    @Binding var searchText: String
    @State private var showAddSheet = false

    private var filteredSkills: [Skill] {
        if searchText.isEmpty { return manager.skills }
        return manager.skills.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSkills: [(source: String, skills: [Skill])] {
        let grouped = Dictionary(grouping: filteredSkills) { $0.source ?? "Local" }
        return grouped.sorted { $0.key < $1.key }.map { (source: $0.key, skills: $0.value) }
    }

    var body: some View {
        List(selection: $selectedSkillID) {
            ForEach(groupedSkills, id: \.source) { group in
                Section {
                    ForEach(group.skills) { skill in
                        SkillRow(skill: skill)
                            .tag(skill.id)
                    }
                } header: {
                    Label {
                        Text(group.source).fontWeight(.semibold)
                    } icon: {
                        Image(systemName: group.source.contains("/") ? "shippingbox" : "folder")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if manager.isLoading {
                ProgressView().controlSize(.large)
            } else if manager.skills.isEmpty {
                ContentUnavailableView(
                    "No Skills Installed",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Add skills from a GitHub repository.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let status = manager.dependencyStatus {
                VersionFooter(status: status)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Label("Add Skill", systemImage: "plus")
                }
                Button { Task { await manager.loadSkills() } } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSkillSheet()
        }
        .navigationTitle("Skills")
        .navigationSubtitle("\(manager.skills.count) installed")
    }
}

// MARK: - Version Footer

private struct VersionFooter: View {
    let status: DependencyStatus

    var body: some View {
        HStack(spacing: 6) {
            if let version = status.currentSkillsVersion {
                Label("skills v\(version)", systemImage: "shippingbox")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Label("skills CLI not found", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Spacer()

            if status.hasUpdate, let latest = status.latestSkillsVersion {
                Button {
                    // Open the Settings window (Environment tab)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("v\(latest)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.borderless)
                .help("Update skills to v\(latest) — open Settings")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - SkillRow

struct SkillRow: View {
    let skill: Skill

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: skill.skillIcon)
                    .foregroundStyle(skill.skillColor)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                Text(skill.displayName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(skill.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
