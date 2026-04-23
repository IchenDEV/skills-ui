import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }

            EnvironmentTab()
                .tabItem { Label("Environment", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 480)
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    appIcon
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SkillsUI")
                            .font(.title2).fontWeight(.bold)
                        Text("Version \(appVersion)")
                            .foregroundStyle(.secondary)
                        Text("macOS 26 · Swift 6 · MIT License")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Links") {
                Link("skills.sh — Marketplace",
                     destination: URL(string: "https://skills.sh")!)
                Link("GitHub Repository",
                     destination: URL(string: "https://github.com/IchenDEV/skills-ui")!)
                Link("Report an Issue",
                     destination: URL(string: "https://github.com/IchenDEV/skills-ui/issues")!)
            }
        }
        .formStyle(.grouped)
        .frame(height: 280)
    }

    private var appIcon: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(
                colors: [Color(red: 0.35, green: 0.35, blue: 0.95),
                         Color(red: 0.35, green: 0.35, blue: 0.95, opacity: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

// MARK: - Environment Tab

private struct EnvironmentTab: View {
    @Environment(SkillsManager.self) private var manager
    @State private var isChecking = false
    @State private var isUpdating = false

    var body: some View {
        Form {
            Section("Runtime") {
                availabilityRow(
                    label: "Node.js",
                    availability: manager.dependencyStatus?.node ?? .notInstalled,
                    note: "brew install node  ·  nodejs.org"
                )
                availabilityRow(
                    label: "npm / npx",
                    availability: manager.dependencyStatus?.node ?? .notInstalled,
                    note: "Bundled with Node.js"
                )
            }

            Section("skills CLI") {
                availabilityRow(
                    label: "skills",
                    availability: manager.dependencyStatus?.skillsCLI ?? .notInstalled,
                    note: "npm install -g skills"
                )

                if let latest = manager.dependencyStatus?.latestSkillsVersion {
                    LabeledContent("Latest on npm", value: "v\(latest)")
                }

                if manager.dependencyStatus?.hasUpdate == true,
                   let latest = manager.dependencyStatus?.latestSkillsVersion {
                    Button {
                        isUpdating = true
                        Task {
                            await manager.updateSkillsCLI()
                            isUpdating = false
                        }
                    } label: {
                        Label(
                            isUpdating ? "Updating…" : "Update to v\(latest)",
                            systemImage: "arrow.up.circle.fill"
                        )
                    }
                    .disabled(isUpdating)
                }
            }

            Section {
                Button {
                    isChecking = true
                    Task {
                        await manager.checkEnvironment()
                        isChecking = false
                    }
                } label: {
                    Label(
                        isChecking ? "Checking…" : "Check Again",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(isChecking)
            }
        }
        .formStyle(.grouped)
        .frame(height: 340)
    }

    private func availabilityRow(
        label: String,
        availability: DependencyStatus.Availability,
        note: String
    ) -> some View {
        LabeledContent(label) {
            switch availability {
            case .installed(let version):
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(version).foregroundStyle(.secondary)
                }
            case .notInstalled:
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    Text("Not found").foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.quaternary)
                    Text(note).font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}
