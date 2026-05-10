import Foundation
import SwiftUI

private struct CommandError: LocalizedError {
    let exitCode: Int32
    var errorDescription: String? { "Command failed (exit \(exitCode))" }
}

private enum SkillAgentError: LocalizedError {
    case missingSource

    var errorDescription: String? {
        switch self {
        case .missingSource:
            "Source metadata is missing, so this skill cannot be installed to additional agents."
        }
    }
}

private struct ListedSkill: Decodable, Sendable {
    let name: String
    let path: String
    let scope: String
    let agents: [String]
}

@Observable
@MainActor
final class SkillsManager {
    var selectedScope: SkillScope = .global
    var globalSkills: [Skill] = []
    var projectSkills: [Skill] = []
    var isLoading = false
    var errorMessage: String?
    var dependencyStatus: DependencyStatus?

    private let homePath: String
    private let globalSkillsPath: String
    private let globalLockPath: String
    private let projectPath: String
    private var lastLoadTime: Date?

    var skills: [Skill] {
        switch selectedScope {
        case .global: globalSkills
        case .project: projectSkills
        }
    }

    var projectDisplayPath: String {
        projectPath.replacingOccurrences(of: homePath, with: "~")
    }

    init() {
        let home = NSHomeDirectory()
        self.homePath = home
        self.globalSkillsPath = "\(home)/.agents/skills"
        self.globalLockPath = "\(home)/.agents/.skill-lock.json"
        self.projectPath = FileManager.default.currentDirectoryPath
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
        let cwd = projectPath

        do {
            let loaded = try await Task.detached {
                let lockEntries = try SkillsManager.loadLockFile(at: lockPath)
                let globalSkills = (try? SkillsManager.loadSkillsFromCLI(
                    scope: .global,
                    cwd: cwd,
                    lockEntries: lockEntries
                )) ?? SkillsManager.loadGlobalSkillsFromFilesystem(
                    globalSkillsPath: skillsPath,
                    lockEntries: lockEntries,
                    home: home
                )
                let projectSkills = (try? SkillsManager.loadProjectSkillsFromCLI(cwd: cwd)) ?? []
                return (globalSkills, projectSkills)
            }.value
            globalSkills = loaded.0
            projectSkills = loaded.1
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

    private nonisolated static func loadSkillsFromCLI(
        scope: SkillScope,
        cwd: String,
        lockEntries: [String: SkillLockEntry]
    ) throws -> [Skill] {
        var args = ["npx", "skills", "ls", "--json"]
        if scope == .global {
            args.insert("-g", at: 3)
        }
        let data = try runCommand(args: args, cwd: cwd)
        let listedSkills = try JSONDecoder().decode([ListedSkill].self, from: data)
        return listedSkills.compactMap { listed in
            try? makeSkill(from: listed, scope: scope, lockEntries: lockEntries)
        }
    }

    private nonisolated static func loadProjectSkillsFromCLI(cwd: String) throws -> [Skill] {
        let lockEntries = (try? loadLockFile(at: "\(cwd)/skills-lock.json")) ?? [:]
        return try loadSkillsFromCLI(scope: .project, cwd: cwd, lockEntries: lockEntries)
    }

    private nonisolated static func loadGlobalSkillsFromFilesystem(
        globalSkillsPath: String,
        lockEntries: [String: SkillLockEntry],
        home: String
    ) -> [Skill] {
        do {
            let agentLinks = try detectAgentLinks(home: home)
            return try scanSkillsDirectory(
                at: globalSkillsPath,
                scope: .global,
                lockEntries: lockEntries,
                agentLinks: agentLinks
            )
        } catch {
            return []
        }
    }

    private nonisolated static func runCommand(args: [String], cwd: String) throws -> Data {
        let process = EnvironmentChecker.makeProcess(args: args)
        process.currentDirectoryURL = URL(filePath: cwd, directoryHint: .isDirectory)
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw CommandError(exitCode: process.terminationStatus)
        }
        return output.fileHandleForReading.readDataToEndOfFile()
    }

    private nonisolated static func runSkillsCommand(args: [String], cwd: String) throws {
        let process = EnvironmentChecker.makeProcess(args: args)
        process.currentDirectoryURL = URL(filePath: cwd, directoryHint: .isDirectory)
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw CommandError(exitCode: process.terminationStatus)
        }
    }

    private nonisolated static func makeSkill(
        from listed: ListedSkill,
        scope: SkillScope,
        lockEntries: [String: SkillLockEntry]
    ) throws -> Skill {
        let fm = FileManager.default
        let skillDirectoryPath = listed.path
        let skillMdPath = "\(skillDirectoryPath)/SKILL.md"
        let content = try String(contentsOfFile: skillMdPath, encoding: .utf8)
        let parsed = SkillParser.parse(fileContent: content)
        let name = parsed.name ?? listed.name

        var hasher = Hasher()
        hasher.combine(content)
        let contentHash = hasher.finalize()

        let lockEntry = lockEntries[name] ?? lockEntries[listed.name]
        let attrs = try? fm.attributesOfItem(atPath: skillDirectoryPath)
        let isSymlink = attrs?[.type] as? FileAttributeType == .typeSymbolicLink

        return Skill(
            id: name,
            name: name,
            description: parsed.description ?? "No description",
            body: parsed.body,
            path: skillDirectoryPath,
            rawContent: content,
            markdownBody: parsed.body,
            contentHash: contentHash,
            source: lockEntry?.source,
            sourceType: lockEntry?.sourceType,
            sourceUrl: lockEntry?.sourceUrl,
            installedAt: parseLockDate(lockEntry?.installedAt),
            updatedAt: parseLockDate(lockEntry?.updatedAt),
            scope: scope,
            agents: agentIDs(from: listed.agents),
            isSymlink: isSymlink
        )
    }

    private nonisolated static func parseLockDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter.date(from: value)
    }

    private nonisolated static func agentIDs(from names: [String]) -> [String] {
        let agentsByName = Dictionary(uniqueKeysWithValues: allAgents.map { ($0.name, $0.id) })
        let agentsByID = Dictionary(uniqueKeysWithValues: allAgents.map { ($0.id, $0.id) })
        return names.compactMap { name in
            agentsByName[name] ?? agentsByID[name]
        }
    }

    private nonisolated static func parseRepositorySkills(from output: String) -> [RepositorySkill] {
        struct Draft {
            var name: String
            var descriptionParts: [String] = []
        }

        var result: [RepositorySkill] = []
        var current: Draft?
        var inList = false

        func finishCurrent() {
            guard let current else { return }
            result.append(RepositorySkill(
                name: current.name,
                description: current.descriptionParts.joined(separator: " ")
            ))
        }

        for line in output.components(separatedBy: .newlines) {
            let clean = stripANSI(from: line)
            if clean.contains("Available Skills") {
                inList = true
                continue
            }
            if clean.contains("Use --skill") {
                break
            }
            guard inList, let content = skillListContent(from: clean), !content.text.isEmpty else {
                continue
            }
            if content.indent == 4, isSkillName(content.text) {
                finishCurrent()
                current = Draft(name: content.text)
            } else if content.indent >= 6 {
                current?.descriptionParts.append(content.text)
            }
        }

        finishCurrent()
        return result
    }

    private nonisolated static func stripANSI(from value: String) -> String {
        value.replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
    }

    private nonisolated static func skillListContent(from line: String) -> (indent: Int, text: String)? {
        guard let separator = line.firstIndex(of: "│") else { return nil }
        let tail = line[line.index(after: separator)...]
        let indent = tail.prefix(while: { $0 == " " }).count
        let text = tail.trimmingCharacters(in: .whitespaces)
        return (indent, text)
    }

    private nonisolated static func isSkillName(_ value: String) -> Bool {
        value.range(of: #"^[A-Za-z0-9][A-Za-z0-9._-]*$"#, options: .regularExpression) != nil
    }

    /// Scans each known agent's skills directory and maps skill folder name → [agentID].
    /// Derives paths from `allAgents` so this stays in sync automatically.
    private nonisolated static func detectAgentLinks(home: String) throws -> [String: [String]] {
        var result: [String: [String]] = [:]
        let fm = FileManager.default

        for agent in allAgents {
            let agentPath = "\(home)/\(agent.pathSuffix)"
            guard fm.fileExists(atPath: agentPath) else { continue }
            let contents = (try? fm.contentsOfDirectory(atPath: agentPath)) ?? []
            for item in contents {
                let itemPath = "\(agentPath)/\(item)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue else { continue }
                result[item, default: []].append(agent.id)
            }
        }
        return result
    }

    private nonisolated static func scanSkillsDirectory(
        at globalSkillsPath: String,
        scope: SkillScope,
        lockEntries: [String: SkillLockEntry],
        agentLinks: [String: [String]]
    ) throws -> [Skill] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: globalSkillsPath) else { return [] }

        let contents = try fm.contentsOfDirectory(atPath: globalSkillsPath)
        var result: [Skill] = []

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
                body: parsed.body,
                path: dirPath,
                rawContent: content,
                markdownBody: parsed.body,
                contentHash: contentHash,
                source: lockEntry?.source,
                sourceType: lockEntry?.sourceType,
                sourceUrl: lockEntry?.sourceUrl,
                installedAt: parseLockDate(lockEntry?.installedAt),
                updatedAt: parseLockDate(lockEntry?.updatedAt),
                scope: scope,
                agents: agentLinks[dir] ?? agentLinks[name] ?? [],
                isSymlink: isSymlink
            )
            result.append(skill)
        }

        return result
    }

    func removeSkill(_ skill: Skill) async throws {
        let name = skill.name
        let scope = skill.scope
        let cwd = projectPath
        try await Task.detached {
            var args = ["npx", "skills", "remove", name, "-y"]
            if scope == .global {
                args.append("-g")
            }
            let process = EnvironmentChecker.makeProcess(args: args)
            process.currentDirectoryURL = URL(filePath: cwd, directoryHint: .isDirectory)
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw CommandError(exitCode: process.terminationStatus)
            }
        }.value
        lastLoadTime = nil
        await loadSkills()
    }

    func updateAgents(for skill: Skill, selectedAgentIDs: [String]) async throws {
        let selected = Set(selectedAgentIDs)
        let installed = Set(skill.agents)
        let agentsToAdd = selected.subtracting(installed).sorted()
        let agentsToRemove = installed.subtracting(selected).sorted()

        guard !agentsToAdd.isEmpty || !agentsToRemove.isEmpty else { return }
        let sourceInput = skill.source ?? skill.sourceUrl
        if !agentsToAdd.isEmpty, sourceInput == nil {
            throw SkillAgentError.missingSource
        }

        let source = sourceInput
        let name = skill.name
        let scope = skill.scope
        let cwd = projectPath

        try await Task.detached {
            if !agentsToRemove.isEmpty {
                var removeArgs = ["npx", "skills", "remove", name, "--agent"]
                removeArgs.append(contentsOf: agentsToRemove)
                removeArgs.append("-y")
                if scope == .global {
                    removeArgs.append("-g")
                }
                try SkillsManager.runSkillsCommand(args: removeArgs, cwd: cwd)
            }

            guard let source, !selected.isEmpty else { return }
            let agentsToInstall = agentsToRemove.isEmpty ? agentsToAdd : selected.sorted()
            guard !agentsToInstall.isEmpty else { return }

            var addArgs = ["npx", "skills", "add", source, "--agent"]
            addArgs.append(contentsOf: agentsToInstall)
            addArgs.append(contentsOf: ["--skill", name, "-y"])
            if scope == .global {
                addArgs.append("-g")
            }
            try SkillsManager.runSkillsCommand(args: addArgs, cwd: cwd)
        }.value

        lastLoadTime = nil
        await loadSkills()
    }

    func previewSkills(from source: String) async throws -> [RepositorySkill] {
        let cwd = projectPath
        return try await Task.detached {
            let data = try SkillsManager.runCommand(args: ["npx", "skills", "add", source, "--list"], cwd: cwd)
            let output = String(data: data, encoding: .utf8) ?? ""
            return SkillsManager.parseRepositorySkills(from: output)
        }.value
    }

    func addSkill(
        from source: String,
        scope explicitScope: SkillScope? = nil,
        skillNames: [String]? = nil
    ) async throws {
        let scope = explicitScope ?? selectedScope
        let cwd = projectPath
        try await Task.detached {
            var args = ["npx", "skills", "add", source]
            if let skillNames, !skillNames.isEmpty {
                args.append(contentsOf: ["--agent", "*", "--skill"])
                args.append(contentsOf: skillNames)
                args.append("-y")
            } else {
                args.append(contentsOf: ["--all", "-y"])
            }
            if scope == .global {
                args.append("-g")
            }
            let process = EnvironmentChecker.makeProcess(args: args)
            process.currentDirectoryURL = URL(filePath: cwd, directoryHint: .isDirectory)
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw CommandError(exitCode: process.terminationStatus)
            }
        }.value
        lastLoadTime = nil
        await loadSkills()
    }

    func checkEnvironment() async {
        dependencyStatus = await EnvironmentChecker.check()
    }

    func updateSkillsCLI() async {
        do {
            try await Task.detached {
                let process = EnvironmentChecker.makeProcess(args: ["npm", "update", "-g", "skills"])
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    throw CommandError(exitCode: process.terminationStatus)
                }
            }.value
        } catch {
            errorMessage = error.localizedDescription
        }
        await checkEnvironment()
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

}
