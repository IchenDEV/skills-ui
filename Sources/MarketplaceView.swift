import SwiftUI

struct MarketplaceView: View {
    @Environment(SkillsManager.self) private var manager
    @State private var searchText = ""
    @State private var results: [MarketplaceSkill] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?
    @State private var installingSkill: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.secondary)

                TextField("Search skills on skills.sh…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { performSearch() }

                Button {
                    performSearch()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)

            Divider()

            if isSearching {
                Spacer()
                ProgressView("Searching skills.sh…")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(error))
                Spacer()
            } else if results.isEmpty && hasSearched {
                Spacer()
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try different search terms."))
                Spacer()
            } else if results.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("Discover Skills", systemImage: "sparkles")
                } description: {
                    Text("Search skills.sh to find and install agent skills.")
                }
                Spacer()
            } else {
                List(results) { skill in
                    MarketplaceRow(skill: skill, isInstalling: installingSkill == skill.id) {
                        installSkill(skill)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Marketplace")
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isSearching = true
        hasSearched = true
        errorMessage = nil

        Task {
            do {
                results = try await MarketplaceService.shared.search(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func installSkill(_ skill: MarketplaceSkill) {
        installingSkill = skill.id
        Task {
            await manager.addSkill(from: skill.source)
            installingSkill = nil
        }
    }
}

struct MarketplaceRow: View {
    @Environment(\.openURL) private var openURL
    let skill: MarketplaceSkill
    let isInstalling: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.linearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(skill.name)
                    .font(.headline)

                if !skill.description.isEmpty {
                    Text(skill.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let author = skill.author {
                        Label(author, systemImage: "person")
                    }
                    Label(skill.source, systemImage: "shippingbox")
                    if let installs = skill.installs {
                        Label(formatNumber(installs), systemImage: "arrow.down.circle")
                    }
                    if let stars = skill.stars {
                        Label("\(stars)", systemImage: "star")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 8) {
                if let urlStr = skill.githubUrl, let url = URL(string: urlStr) {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderless)
                }

                Button {
                    onInstall()
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Install", systemImage: "plus.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isInstalling)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000)
        }
        return "\(n)"
    }
}
