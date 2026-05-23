import SwiftUI

struct SkillDetailView: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.openURL) private var openURL
    let skill: Skill
    @State private var showDeleteConfirmation = false
    @State private var showRawContent = false
    @State private var showManageAgents = false
    @State private var removeError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 32)

                metadataSection
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)

                Divider()
                    .padding(.horizontal, 32)

                contentSection
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 2) {
                    Button {
                        manager.revealInFinder(skill)
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Reveal in Finder")

                    if let url = skill.githubURL {
                        Button {
                            openURL(url)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                        }
                        .help("Open on GitHub")
                    }

                    Button {
                        showManageAgents = true
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .help("Manage Agents…")

                    Menu {
                        Button {
                            showRawContent.toggle()
                        } label: {
                            Label(showRawContent ? "Show Rendered" : "Show Source", systemImage: "doc.plaintext")
                        }

                        Button {
                            showManageAgents = true
                        } label: {
                            Label("Manage Agents…", systemImage: "person.2")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Remove Skill…", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Remove \(skill.displayName)?", isPresented: $showDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                Task {
                    do {
                        try await manager.removeSkill(skill)
                    } catch {
                        removeError = error.localizedDescription
                    }
                }
            }
        } message: {
            Text(removeConfirmationMessage)
        }
        .alert("Remove Failed", isPresented: Binding(get: { removeError != nil }, set: { _ in removeError = nil })) {
            Button("OK") { removeError = nil }
        } message: {
            Text(removeError ?? "")
        }
        .sheet(isPresented: $showManageAgents) {
            ManageAgentsSheet(skill: skill)
        }
        .navigationTitle(skill.displayName)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconGradient)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: skill.skillIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: skill.skillColor.opacity(0.3), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.displayName)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(skill.name)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(skill.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
            GridRow {
                MetadataItem(label: "Source", value: skill.source ?? "Local", icon: "shippingbox")
                MetadataItem(label: "Scope", value: skill.scope.rawValue, icon: skill.scope.icon)
                MetadataItem(label: "Type", value: skill.isSymlink ? "Symlink" : "Copy", icon: skill.isSymlink ? "link" : "doc.on.doc")
            }
            GridRow {
                if let date = skill.installedAt {
                    MetadataItem(label: "Installed", value: date.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                } else {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                }

                if !skill.agents.isEmpty {
                    let names = skill.agents.compactMap { id in SkillsManager.allAgents.first(where: { $0.id == id })?.name }
                    MetadataItem(label: "Agents", value: names.joined(separator: ", "), icon: "cpu")
                } else {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                }

                MetadataItem(label: "Path", value: (skill.path as NSString).lastPathComponent, icon: "folder", fullValue: skill.path)
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SKILL.md")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(skill.rawContent.count) chars")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }

            if showRawContent {
                GroupBox {
                    Text(skill.rawContent)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            } else {
                SkillMarkdownView(
                    markdown: skill.markdownBody,
                    baseURL: URL(filePath: skill.path, directoryHint: .isDirectory),
                    renderKey: skill.renderCacheKey
                )
            }
        }
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [skill.skillColor, skill.skillColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var removeConfirmationMessage: String {
        switch skill.scope {
        case .global:
            "This will uninstall the skill from all global agents. You can reinstall it later from \(skill.source ?? "its source")."
        case .project:
            "This will uninstall the skill from the current project. You can reinstall it later from \(skill.source ?? "its source")."
        }
    }
}

// MARK: - Manage Agents Sheet

struct ManageAgentsSheet: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    let skill: Skill
    @State private var selectedAgents: Set<String> = []
    @State private var isApplying = false
    @State private var errorMessage: String?

    private var installedAgentIDs: Set<String> {
        Set(skill.agents)
    }

    private var agentsToAdd: Set<String> {
        selectedAgents.subtracting(installedAgentIDs)
    }

    private var agentsToRemove: Set<String> {
        installedAgentIDs.subtracting(selectedAgents)
    }

    private var hasChanges: Bool {
        !agentsToAdd.isEmpty || !agentsToRemove.isEmpty
    }

    private var canApply: Bool {
        hasChanges && !isApplying && (agentsToAdd.isEmpty || installSource != nil)
    }

    private var installSource: String? {
        skill.source ?? skill.sourceUrl
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.2")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)

                Text("Manage Agents")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose where **\(skill.displayName)** is available")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Agent list
            List(SkillsManager.allAgents, id: \.id) { agent in
                let isInstalled = installedAgentIDs.contains(agent.id)
                Toggle(isOn: Binding(
                    get: { selectedAgents.contains(agent.id) },
                    set: { isSelected in
                        if isSelected {
                            selectedAgents.insert(agent.id)
                        } else {
                            selectedAgents.remove(agent.id)
                        }
                    }
                )) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(agent.name)
                                .font(.body)
                            Text("~/\(agent.pathSuffix)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        AgentChangeLabel(
                            isInstalled: isInstalled,
                            isSelected: selectedAgents.contains(agent.id)
                        )
                    }
                }
                .toggleStyle(.checkbox)
                .tag(agent.id)
                .listRowSeparator(.visible)
            }
            .listStyle(.inset)

            Divider()

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(changeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !agentsToAdd.isEmpty && installSource == nil {
                        Text("Missing source metadata")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Button {
                    applyChanges()
                } label: {
                    if isApplying {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Apply")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canApply)
            }
            .padding(16)
        }
        .frame(width: 460, height: 520)
        .onAppear {
            selectedAgents = installedAgentIDs
        }
        .alert("Agent Update Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var changeSummary: String {
        if !hasChanges { return "\(selectedAgents.count) selected" }
        var parts: [String] = []
        if !agentsToAdd.isEmpty {
            parts.append("+\(agentsToAdd.count)")
        }
        if !agentsToRemove.isEmpty {
            parts.append("-\(agentsToRemove.count)")
        }
        return parts.joined(separator: " ")
    }

    private func applyChanges() {
        isApplying = true
        errorMessage = nil
        Task {
            do {
                try await manager.updateAgents(for: skill, selectedAgentIDs: Array(selectedAgents))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isApplying = false
        }
    }
}

private struct AgentChangeLabel: View {
    let isInstalled: Bool
    let isSelected: Bool

    var body: some View {
        if isInstalled && isSelected {
            Text("Current")
                .font(.caption)
                .foregroundStyle(.green)
        } else if !isInstalled && isSelected {
            Text("Will install")
                .font(.caption)
                .foregroundStyle(.blue)
        } else if isInstalled && !isSelected {
            Text("Will remove")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String
    let icon: String
    var fullValue: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(fullValue ?? value)
            }
        }
    }
}
