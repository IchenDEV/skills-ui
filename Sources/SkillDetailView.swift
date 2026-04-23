import SwiftUI

struct SkillDetailView: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.openURL) private var openURL
    let skill: Skill
    @State private var showDeleteConfirmation = false
    @State private var showRawContent = false
    @State private var showAddToAgents = false
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
                        showAddToAgents = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .help("Add to Agents…")

                    Menu {
                        Button {
                            showRawContent.toggle()
                        } label: {
                            Label(showRawContent ? "Show Rendered" : "Show Source", systemImage: "doc.plaintext")
                        }

                        Button {
                            showAddToAgents = true
                        } label: {
                            Label("Add to Agents…", systemImage: "person.badge.plus")
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
            Text("This will uninstall the skill from all agents. You can reinstall it later from \(skill.source ?? "its source").")
        }
        .alert("Remove Failed", isPresented: Binding(get: { removeError != nil }, set: { _ in removeError = nil })) {
            Button("OK") { removeError = nil }
        } message: {
            Text(removeError ?? "")
        }
        .sheet(isPresented: $showAddToAgents) {
            AddToAgentsSheet(skill: skill)
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
}

// MARK: - Add to Agents Sheet

struct AddToAgentsSheet: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    let skill: Skill
    @State private var selectedAgents: Set<String> = []
    @State private var isInstalling = false

    private var installedAgentIDs: Set<String> {
        Set(skill.agents)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)

                Text("Add to Agents")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Install **\(skill.displayName)** to additional agents")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Agent list
            List(SkillsManager.allAgents, id: \.id, selection: $selectedAgents) { agent in
                let isInstalled = installedAgentIDs.contains(agent.id)
                HStack {
                    VStack(alignment: .leading) {
                        Text(agent.name)
                            .font(.body)
                        Text("~/\(agent.pathSuffix)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    if isInstalled {
                        Text("Installed")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
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

                Text("\(selectedAgents.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    isInstalling = true
                    Task {
                        await manager.installToAgents(skill, agentIDs: Array(selectedAgents))
                        isInstalling = false
                        dismiss()
                    }
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Install")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedAgents.isEmpty || isInstalling)
            }
            .padding(16)
        }
        .frame(width: 420, height: 480)
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
