import SwiftUI

struct AddSkillSheet: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    @State private var sourceText = ""
    @State private var isInstalling = false
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
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("owner/repo or URL", text: $sourceText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { install() }

                if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 28)

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
                        Text("Install")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(sourceText.trimmingCharacters(in: .whitespaces).isEmpty || isInstalling)
            }
            .padding(20)
        }
        .frame(width: 440, height: 420)
    }

    private func install() {
        guard !sourceText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isInstalling = true
        errorMessage = nil
        Task {
            await manager.addSkill(from: sourceText)
            isInstalling = false
            if manager.errorMessage == nil {
                dismiss()
            } else {
                errorMessage = manager.errorMessage
            }
        }
    }
}
