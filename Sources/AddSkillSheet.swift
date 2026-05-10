import SwiftUI

struct AddSkillSheet: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    @State private var sourceText = ""
    @State private var isInstalling = false
    @State private var isPreviewing = false
    @State private var previewSkills: [RepositorySkill] = []
    @State private var selectedSkillNames: Set<String> = []
    @State private var previewSource: String?
    @State private var errorMessage: String?

    private let examples = [
        ("vercel-labs/agent-skills", "Official Vercel agent skills"),
        ("lijigang/ljg-skills", "LJG custom skills collection"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)

                Text("Add Skills")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter a GitHub repo (owner/repo) or a full URL")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Label("Installing to \(manager.selectedScope.rawValue.lowercased()) scope", systemImage: manager.selectedScope.icon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Input
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TextField("owner/repo or URL", text: $sourceText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { preview() }

                    Button {
                        preview()
                    } label: {
                        if isPreviewing {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            Label("Preview", systemImage: "list.bullet.rectangle")
                        }
                    }
                    .disabled(trimmedSource.isEmpty || isPreviewing || isInstalling)
                }

                if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 28)
            .onChange(of: sourceText) { _, _ in
                clearPreview()
            }

            if previewSkills.isEmpty {
                // Quick picks
                VStack(alignment: .leading, spacing: 8) {
                    Text("Popular Sources")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(examples, id: \.0) { repo, desc in
                        Button {
                            sourceText = repo
                        } label: {
                            HStack {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(repo)
                                        .font(.system(.callout, design: .monospaced))
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(28)
            } else {
                previewSection
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
            }

            Spacer()

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    install()
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        Text(installButtonTitle)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(installDisabled)
            }
            .padding(20)
        }
        .frame(width: 520, height: 560)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Available Skills")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("All") {
                    selectedSkillNames = Set(previewSkills.map(\.name))
                }
                .buttonStyle(.borderless)

                Button("None") {
                    selectedSkillNames.removeAll()
                }
                .buttonStyle(.borderless)
            }

            List(previewSkills) { skill in
                Toggle(isOn: Binding(
                    get: { selectedSkillNames.contains(skill.name) },
                    set: { isSelected in
                        if isSelected {
                            selectedSkillNames.insert(skill.name)
                        } else {
                            selectedSkillNames.remove(skill.name)
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(skill.name)
                            .font(.system(.callout, design: .monospaced))
                        if !skill.description.isEmpty {
                            Text(skill.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                }
                .toggleStyle(.checkbox)
            }
            .listStyle(.inset)
            .frame(minHeight: 230)
        }
    }

    private var trimmedSource: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var installButtonTitle: String {
        guard !previewSkills.isEmpty else { return "Install All" }
        return "Install \(selectedSkillNames.count)"
    }

    private var installDisabled: Bool {
        trimmedSource.isEmpty || isInstalling || isPreviewing || (!previewSkills.isEmpty && selectedSkillNames.isEmpty)
    }

    private func preview() {
        guard !trimmedSource.isEmpty else { return }
        let source = trimmedSource
        isPreviewing = true
        errorMessage = nil
        Task {
            defer { isPreviewing = false }
            do {
                let skills = try await manager.previewSkills(from: source)
                guard source == trimmedSource else { return }
                previewSkills = skills
                selectedSkillNames = Set(skills.map(\.name))
                previewSource = source
                if skills.isEmpty {
                    errorMessage = "No skills found in this source."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func install() {
        guard !trimmedSource.isEmpty else { return }
        isInstalling = true
        errorMessage = nil
        Task {
            do {
                let names = previewSource == trimmedSource && !previewSkills.isEmpty
                    ? Array(selectedSkillNames).sorted()
                    : nil
                try await manager.addSkill(from: trimmedSource, skillNames: names)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isInstalling = false
        }
    }

    private func clearPreview() {
        previewSkills.removeAll()
        selectedSkillNames.removeAll()
        previewSource = nil
        errorMessage = nil
    }
}
