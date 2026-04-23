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
                        Text(group.source)
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: group.source.contains("/") ? "shippingbox" : "folder")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if manager.isLoading {
                ProgressView()
                    .controlSize(.large)
            } else if manager.skills.isEmpty {
                ContentUnavailableView("No Skills Installed", systemImage: "puzzlepiece.extension", description: Text("Add skills from a GitHub repository."))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Skill", systemImage: "plus")
                }

                Button {
                    Task { await manager.loadSkills() }
                } label: {
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

struct SkillRow: View {
    let skill: Skill

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: skillIcon)
                    .foregroundStyle(skillColor)
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

    private var skillIcon: String {
        if skill.name.hasPrefix("ljg-") { return "character.book.closed.fill" }
        if skill.name.contains("react") { return "atom" }
        if skill.name.contains("design") { return "paintbrush.fill" }
        if skill.name.contains("find") { return "magnifyingglass" }
        if skill.name.contains("browser") { return "globe" }
        if skill.name.contains("paper") { return "doc.text.fill" }
        if skill.name.contains("dogfood") { return "ladybug.fill" }
        if skill.name.contains("sandbox") { return "shippingbox.fill" }
        if skill.name.contains("a2a") { return "arrow.left.arrow.right" }
        if skill.name.contains("invest") { return "chart.line.uptrend.xyaxis" }
        if skill.name.contains("rank") { return "list.number" }
        if skill.name.contains("relationship") { return "person.2.fill" }
        if skill.name.contains("roundtable") { return "person.3.fill" }
        if skill.name.contains("plain") { return "textformat" }
        return "puzzlepiece.extension.fill"
    }

    private var skillColor: Color {
        if skill.name.hasPrefix("ljg-") { return .orange }
        if skill.name.contains("react") { return .cyan }
        if skill.name.contains("design") { return .pink }
        if skill.name.contains("find") { return .blue }
        if skill.name.contains("browser") { return .green }
        if skill.name.contains("vercel") { return .purple }
        if skill.name.contains("dogfood") { return .red }
        if skill.name.contains("a2a") { return .indigo }
        return .secondary
    }
}
