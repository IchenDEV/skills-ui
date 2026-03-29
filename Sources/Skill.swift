import Foundation

struct Skill: Identifiable, Hashable, Sendable {
    let id: String  // same as name
    let name: String
    let description: String
    let path: String
    let rawContent: String
    let source: String?        // e.g. "vercel-labs/agent-skills"
    let sourceType: String?    // "github", "local", etc.
    let sourceUrl: String?
    let installedAt: Date?
    let updatedAt: Date?
    let scope: SkillScope
    let agents: [String]       // which agents have this skill
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
