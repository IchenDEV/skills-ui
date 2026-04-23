import SwiftUI

struct SkillDetailView: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.openURL) private var openURL
    let skill: Skill
    @State private var showDeleteConfirmation = false
    @State private var showRawContent = false
    @State private var showAddToAgents = false

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
                Task { await manager.removeSkill(skill) }
            }
        } message: {
            Text("This will uninstall the skill from all agents. You can reinstall it later from \(skill.source ?? "its source").")
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
                        Image(systemName: skillIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)

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
                    MetadataItem(label: "Agents", value: skill.agents.joined(separator: ", "), icon: "cpu")
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

    private var iconColor: Color {
        if skill.name.hasPrefix("ljg-") { return .orange }
        if skill.name.contains("react") { return .cyan }
        if skill.name.contains("design") { return .pink }
        if skill.name.contains("find") { return .blue }
        if skill.name.contains("browser") { return .green }
        if skill.name.contains("vercel") { return .purple }
        if skill.name.contains("dogfood") { return .red }
        if skill.name.contains("a2a") { return .indigo }
        return .gray
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [iconColor, iconColor.opacity(0.7)],
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

    private var installedAgentNames: Set<String> {
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
                let isInstalled = installedAgentNames.contains(agent.name)
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
