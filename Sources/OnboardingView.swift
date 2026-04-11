import SwiftUI

struct OnboardingView: View {
    @Environment(SkillsManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    @State private var isChecking = false

    /// Onboarding can be skipped only when Node is present.
    /// If Node is missing, the sheet is locked until the user installs it.
    private var canSkip: Bool { manager.dependencyStatus?.nodeReady == true }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            stepsSection
            Spacer()
            Divider()
            footerSection
        }
        .frame(width: 500, height: 460)
        // Prevent closing via Esc or swipe when Node is missing
        .interactiveDismissDisabled(!canSkip)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.35, green: 0.35, blue: 0.95),
                                 Color(red: 0.35, green: 0.35, blue: 0.95, opacity: 0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("Setup Required")
                .font(.title2).fontWeight(.bold)

            Text("SkillsUI needs a few tools to manage AI agent skills.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SetupStep(
                number: 1,
                title: "Node.js",
                subtitle: "JavaScript runtime required to run the skills package manager.",
                availability: manager.dependencyStatus?.node ?? .notInstalled,
                installCommand: "brew install node",
                learnMoreURL: "https://nodejs.org/en/download",
                badge: "Required"
            )
            SetupStep(
                number: 2,
                title: "skills CLI",
                subtitle: "Installs and manages AI agent skills across all your coding tools.",
                availability: manager.dependencyStatus?.skillsCLI ?? .notInstalled,
                installCommand: "npm install -g skills",
                learnMoreURL: "https://skills.sh",
                badge: "Recommended"
            )
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }

    private var footerSection: some View {
        HStack {
            if canSkip {
                Button("Skip for Now") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isChecking = true
                Task {
                    await manager.checkEnvironment()
                    isChecking = false
                    if manager.dependencyStatus?.skillsReady == true { dismiss() }
                }
            } label: {
                if isChecking {
                    ProgressView().controlSize(.small).padding(.horizontal, 8)
                } else {
                    Label("Check Again", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isChecking)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }
}

// MARK: - SetupStep

private struct SetupStep: View {
    @Environment(\.openURL) private var openURL
    let number: Int
    let title: String
    let subtitle: String
    let availability: DependencyStatus.Availability
    let installCommand: String
    let learnMoreURL: String
    let badge: String

    @State private var copied = false

    private var isInstalled: Bool {
        if case .installed = availability { return true }
        return false
    }

    private var isRequired: Bool { badge == "Required" }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            stepBadge
            VStack(alignment: .leading, spacing: 6) {
                titleRow
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !isInstalled { installRow }
            }
        }
    }

    private var stepBadge: some View {
        ZStack {
            Circle()
                .fill(isInstalled
                    ? Color.green.opacity(0.15)
                    : (isRequired ? Color.red.opacity(0.12) : Color.orange.opacity(0.12)))
                .frame(width: 36, height: 36)
            if isInstalled {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Text("\(number)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isRequired ? .red : .orange)
            }
        }
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            Text(title).fontWeight(.semibold)
            switch availability {
            case .installed(let version):
                statusPill(version, color: .green)
            case .notInstalled:
                statusPill(badge, color: isRequired ? .red : .orange)
            }
        }
    }

    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var installRow: some View {
        HStack(spacing: 8) {
            Text(installCommand)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(installCommand, forType: .string)
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            } label: {
                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")

            Button {
                if let url = URL(string: learnMoreURL) { openURL(url) }
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Learn more")
        }
    }
}
