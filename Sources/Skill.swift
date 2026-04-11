import Foundation

struct Skill: Identifiable, Hashable, Sendable {
    let id: String  // same as name
    let name: String
    let description: String
    let body: String
    let path: String
    let rawContent: String
    let source: String?        // e.g. "vercel-labs/agent-skills"
    let sourceType: String?    // "github", "local", etc.
    let sourceUrl: String?
    let installedAt: Date?
    let updatedAt: Date?
    let scope: SkillScope
    let agents: [String]       // agent IDs (e.g. "claude-code")
    let isSymlink: Bool

    var displayName: String {
        name.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }

    var sourceRepo: String? {
        source
    }

    var githubURL: URL? {
        guard let source, sourceType == "github" else { return nil }
        return URL(string: "https://github.com/\(source)")
    }

    var skillIcon: String {
        if name.hasPrefix("ljg-") { return "character.book.closed.fill" }
        if name.contains("react") { return "atom" }
        if name.contains("design") { return "paintbrush.fill" }
        if name.contains("find") { return "magnifyingglass" }
        if name.contains("browser") { return "globe" }
        if name.contains("paper") { return "doc.text.fill" }
        if name.contains("dogfood") { return "ladybug.fill" }
        if name.contains("sandbox") { return "shippingbox.fill" }
        if name.contains("a2a") { return "arrow.left.arrow.right" }
        if name.contains("invest") { return "chart.line.uptrend.xyaxis" }
        if name.contains("rank") { return "list.number" }
        if name.contains("relationship") { return "person.2.fill" }
        if name.contains("roundtable") { return "person.3.fill" }
        if name.contains("plain") { return "textformat" }
        return "puzzlepiece.extension.fill"
    }
}

enum SkillScope: String, CaseIterable, Sendable {
    case global = "Global"
    case project = "Project"

    var icon: String {
        switch self {
        case .global: "globe"
        case .project: "folder"
        }
    }
}
