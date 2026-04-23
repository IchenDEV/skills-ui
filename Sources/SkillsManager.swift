import Foundation
import SwiftUI

@Observable
@MainActor
final class SkillsManager {
    var skills: [Skill] = []
    var isLoading = false
    var errorMessage: String?

    private let homePath: String
    private let globalSkillsPath: String
    private let globalLockPath: String
    private var lastLoadTime: Date?

    init() {
        let home = NSHomeDirectory()
        self.homePath = home
        self.globalSkillsPath = "\(home)/.agents/skills"
        self.globalLockPath = "\(home)/.agents/.skill-lock.json"
    }

    func loadSkills() async {
        // Debounce rapid reloads
        if let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < 2 { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        let skillsPath = globalSkillsPath
        let lockPath = globalLockPath
        let home = homePath

        do {
            skills = try await Task.detached {
                let lockEntries = try SkillsManager.loadLockFile(at: lockPath)
                let agentLinks = try SkillsManager.detectAgentLinks(home: home)
                return try SkillsManager.scanSkillsDirectory(
                    at: skillsPath,
                    lockEntries: lockEntries,
                    agentLinks: agentLinks
                )
            }.value
            lastLoadTime = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private nonisolated static func loadLockFile(at path: String) throws -> [String: SkillLockEntry] {
        guard FileManager.default.fileExists(atPath: path) else { return [:] }
        let data = try Data(contentsOf: URL(filePath: path))
        let lockFile = try JSONDecoder().decode(SkillLockFile.self, from: data)
        return lockFile.skills
    }

    private nonisolated static func detectAgentLinks(home: String) throws -> [String: [String]] {
        let agentDirs: [(name: String, path: String)] = [
            ("Amp", "\(home)/.agents/skills"),
            ("Claude Code", "\(home)/.claude/skills"),
            ("Codex", "\(home)/.codex/skills"),
            ("Cursor", "\(home)/.cursor/skills"),
            ("Windsurf", "\(home)/.codeium/windsurf/skills"),
            ("Gemini CLI", "\(home)/.gemini/skills"),
            ("Copilot", "\(home)/.copilot/skills"),
            ("Roo Code", "\(home)/.roo/skills"),
            ("Cline", "\(home)/.agents/skills"),
            ("OpenCode", "\(home)/.config/opencode/skills"),
            ("Trae", "\(home)/.trae/skills"),
            ("Augment", "\(home)/.augment/skills"),
            ("Droid", "\(home)/.factory/skills"),
            ("Kiro", "\(home)/.kiro/skills"),
            ("Warp", "\(home)/.agents/skills"),
        ]

        var result: [String: [String]] = [:]
        let fm = FileManager.default

        for agent in agentDirs {
            guard fm.fileExists(atPath: agent.path) else { continue }
            let contents = try fm.contentsOfDirectory(atPath: agent.path)
            for item in contents {
                let itemPath = "\(agent.path)/\(item)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue else { continue }
                result[item, default: []].append(agent.name)
            }
        }
        return result
    }

    private nonisolated static func scanSkillsDirectory(
        at globalSkillsPath: String,
        lockEntries: [String: SkillLockEntry],
        agentLinks: [String: [String]]
    ) throws -> [Skill] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: globalSkillsPath) else { return [] }

        let contents = try fm.contentsOfDirectory(atPath: globalSkillsPath)
        var result: [Skill] = []

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for dir in contents.sorted() {
            let dirPath = "\(globalSkillsPath)/\(dir)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }

            let skillMdPath = "\(dirPath)/SKILL.md"
            guard fm.fileExists(atPath: skillMdPath) else { continue }

            let content = try String(contentsOfFile: skillMdPath, encoding: .utf8)
            let parsed = SkillParser.parse(fileContent: content)

            guard let name = parsed.name else { continue }

            var hasher = Hasher()
            hasher.combine(content)
            let contentHash = hasher.finalize()

            let lockEntry = lockEntries[name] ?? lockEntries[dir]

            let attrs = try fm.attributesOfItem(atPath: dirPath)
            let isSymlink = attrs[.type] as? FileAttributeType == .typeSymbolicLink

            let skill = Skill(
                id: name,
                name: name,
                description: parsed.description ?? "No description",
                path: dirPath,
                rawContent: content,
                markdownBody: parsed.body,
                contentHash: contentHash,
                source: lockEntry?.source,
                sourceType: lockEntry?.sourceType,
                sourceUrl: lockEntry?.sourceUrl,
                installedAt: lockEntry.flatMap { dateFormatter.date(from: $0.installedAt) },
                updatedAt: lockEntry.flatMap { dateFormatter.date(from: $0.updatedAt) },
                scope: .global,
                agents: agentLinks[dir] ?? agentLinks[name] ?? [],
                isSymlink: isSymlink
            )
            result.append(skill)
        }

        return result
    }

    func removeSkill(_ skill: Skill) async {
        let name = skill.name
        do {
            try await Task.detached {
                let process = Process()
                process.executableURL = URL(filePath: "/usr/bin/env")
                process.arguments = ["npx", "skills", "remove", name, "-y", "-g"]
                try process.run()
                process.waitUntilExit()
            }.value
            await loadSkills()
        } catch {
            errorMessage = "Failed to remove skill: \(error.localizedDescription)"
        }
    }

    func addSkill(from source: String) async {
        do {
            try await Task.detached {
                let process = Process()
                process.executableURL = URL(filePath: "/usr/bin/env")
                process.arguments = ["npx", "skills", "add", source, "--all", "-g", "-y"]
                try process.run()
                process.waitUntilExit()
            }.value
            await loadSkills()
        } catch {
            errorMessage = "Failed to add skill: \(error.localizedDescription)"
        }
    }

    func checkForUpdates() async {
        do {
            try await Task.detached {
                let process = Process()
                process.executableURL = URL(filePath: "/usr/bin/env")
                process.arguments = ["npx", "skills", "check"]
                try process.run()
                process.waitUntilExit()
            }.value
        } catch {
            errorMessage = "Failed to check updates: \(error.localizedDescription)"
        }
    }

    func revealInFinder(_ skill: Skill) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: skill.path)
    }

    /// All known agents with their global skills paths
    nonisolated static let allAgents: [(id: String, name: String, pathSuffix: String)] = [
        ("amp", "Amp", ".agents/skills"),
        ("claude-code", "Claude Code", ".claude/skills"),
        ("codex", "Codex", ".codex/skills"),
        ("cursor", "Cursor", ".cursor/skills"),
        ("windsurf", "Windsurf", ".codeium/windsurf/skills"),
        ("gemini-cli", "Gemini CLI", ".gemini/skills"),
        ("github-copilot", "Copilot", ".copilot/skills"),
        ("roo", "Roo Code", ".roo/skills"),
        ("cline", "Cline", ".cline/skills"),
        ("opencode", "OpenCode", ".config/opencode/skills"),
        ("trae", "Trae", ".trae/skills"),
        ("augment", "Augment", ".augment/skills"),
        ("droid", "Droid", ".factory/skills"),
        ("kiro-cli", "Kiro", ".kiro/skills"),
        ("warp", "Warp", ".warp/skills"),
        ("deepagents", "Deep Agents", ".deepagents/agent/skills"),
        ("antigravity", "Antigravity", ".gemini/antigravity/skills"),
        ("openhands", "OpenHands", ".openhands/skills"),
        ("qwen-code", "Qwen Code", ".qwen/skills"),
        ("trae-cn", "Trae CN", ".trae-cn/skills"),
    ]

    /// Install a skill to specific agents via symlink
    func installToAgents(_ skill: Skill, agentIDs: [String]) async {
        let home = homePath
        let skillPath = skill.path
        let agents = agentIDs
        do {
            try await Task.detached {
                let fm = FileManager.default
                for agentID in agents {
                    guard let agent = SkillsManager.allAgents.first(where: { $0.id == agentID }) else { continue }
                    let agentSkillsDir = "\(home)/\(agent.pathSuffix)"
                    let targetDir = "\(agentSkillsDir)/\((skillPath as NSString).lastPathComponent)"

                    // Skip if already exists
                    if fm.fileExists(atPath: targetDir) { continue }

                    // Create parent dir if needed
                    try fm.createDirectory(atPath: agentSkillsDir, withIntermediateDirectories: true)

                    // Create relative symlink
                    try fm.createSymbolicLink(atPath: targetDir, withDestinationPath: skillPath)
                }
            }.value
            lastLoadTime = nil
            await loadSkills()
        } catch {
            errorMessage = "Failed to install: \(error.localizedDescription)"
        }
    }

    var groupedBySource: [(source: String, skills: [Skill])] {
        let grouped = Dictionary(grouping: skills) { $0.source ?? "Local" }
        return grouped.sorted { $0.key < $1.key }.map { (source: $0.key, skills: $0.value) }
    }
}
