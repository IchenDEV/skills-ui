import Foundation

struct SkillLockFile: Codable, Sendable {
    let version: Int
    let skills: [String: SkillLockEntry]
    let dismissed: Dismissed?
    let lastSelectedAgents: [String]?

    struct Dismissed: Codable, Sendable {
        let findSkillsPrompt: Bool?
    }
}

struct SkillLockEntry: Codable, Sendable {
    let source: String
    let sourceType: String
    let sourceUrl: String
    let skillPath: String?
    let skillFolderHash: String?
    let pluginName: String?
    let installedAt: String
    let updatedAt: String
}
