import Foundation

// MARK: - DependencyStatus

struct DependencyStatus: Sendable {
    enum Availability: Sendable, Equatable {
        case installed(version: String)
        case notInstalled
    }

    var node: Availability = .notInstalled
    var skillsCLI: Availability = .notInstalled
    var latestSkillsVersion: String?

    /// Node.js is the hard runtime requirement (npx ships with it).
    var nodeReady: Bool {
        if case .installed = node { return true }
        return false
    }

    /// skills globally installed is recommended; npx auto-downloads as a fallback.
    var skillsReady: Bool {
        if case .installed = skillsCLI { return true }
        return false
    }

    var hasUpdate: Bool {
        guard case .installed(let current) = skillsCLI,
              let latest = latestSkillsVersion else { return false }
        return isNewerVersion(latest, than: current)
    }

    var currentSkillsVersion: String? {
        if case .installed(let v) = skillsCLI { return v }
        return nil
    }

    var nodeVersion: String? {
        if case .installed(let v) = node { return v }
        return nil
    }
}

/// Semantic version comparison: returns true if `a` is strictly newer than `b`.
private func isNewerVersion(_ a: String, than b: String) -> Bool {
    let av = a.split(separator: ".").compactMap { Int($0) }
    let bv = b.split(separator: ".").compactMap { Int($0) }
    for (x, y) in zip(av, bv) where x != y { return x > y }
    return av.count > bv.count
}

// MARK: - EnvironmentChecker

enum EnvironmentChecker {
    /// Runs all checks concurrently and returns a fully-populated status.
    static func check() async -> DependencyStatus {
        async let nodeAv = checkNode()
        async let skillsAv = checkSkillsCLI()
        async let latestVer = fetchLatestSkillsVersion()
        return await DependencyStatus(node: nodeAv, skillsCLI: skillsAv, latestSkillsVersion: latestVer)
    }

    private static func checkNode() async -> DependencyStatus.Availability {
        await Task.detached {
            guard let v = shellOutput(["node", "--version"]) else { return .notInstalled }
            return .installed(version: v)
        }.value
    }

    private static func checkSkillsCLI() async -> DependencyStatus.Availability {
        await Task.detached {
            // npm list exits 1 when packages are missing but still outputs partial JSON —
            // parse the output regardless of exit code.
            let process = makeProcess(args: ["npm", "list", "-g", "skills", "--depth=0", "--json"])
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let deps = json["dependencies"] as? [String: Any],
                  let info = deps["skills"] as? [String: Any],
                  let version = info["version"] as? String else { return .notInstalled }
            return .installed(version: version)
        }.value
    }

    private static func fetchLatestSkillsVersion() async -> String? {
        guard let url = URL(string: "https://registry.npmjs.org/skills/latest") else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["version"] as? String else { return nil }
        return version
    }

    private static func shellOutput(_ args: [String]) -> String? {
        let process = makeProcess(args: args)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns a Process with an enriched PATH so GUI app context can find node/npm.
    static func makeProcess(args: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = commandSearchPath(
            existingPath: env["PATH"],
            loginShellPath: cachedLoginShellPath
        )
        process.environment = env
        return process
    }

    static func commandSearchPath(existingPath: String?, loginShellPath: String? = cachedLoginShellPath) -> String {
        let home = NSHomeDirectory()
        let shellEntries = (loginShellPath ?? "")
            .split(separator: ":")
            .map(String.init)
        let fallbackEntries = [
            "\(home)/n/bin",
            "\(home)/.n/bin",
            "\(home)/.volta/bin",
            "\(home)/.local/bin",
            "\(home)/.npm-global/bin",
            "\(home)/.nodenv/shims",
            "\(home)/.asdf/shims",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
        ]
        let inheritedEntries = (existingPath ?? "")
            .split(separator: ":")
            .map(String.init)

        return (shellEntries + fallbackEntries + inheritedEntries)
            .reduce(into: [String]()) { entries, entry in
                guard !entry.isEmpty, !entries.contains(entry) else { return }
                entries.append(entry)
            }
            .joined(separator: ":")
    }

    private static let cachedLoginShellPath = readLoginShellPath()

    private static func readLoginShellPath() -> String? {
        let env = ProcessInfo.processInfo.environment
        let shell = env["SHELL"] ?? "/bin/zsh"
        guard FileManager.default.isExecutableFile(atPath: shell) else { return nil }

        let begin = "__SKILLSUI_PATH_BEGIN__"
        let end = "__SKILLSUI_PATH_END__"
        let process = Process()
        process.executableURL = URL(filePath: shell)
        process.arguments = [
            "-lic",
            "printf '%s\\n%s\\n%s\\n' '\(begin)' \"$PATH\" '\(end)'",
        ]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        return markedValue(in: text, begin: begin, end: end)
    }

    private static func markedValue(in text: String, begin: String, end: String) -> String? {
        guard let beginRange = text.range(of: begin),
              let endRange = text.range(of: end, range: beginRange.upperBound..<text.endIndex) else {
            return nil
        }

        return String(text[beginRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
