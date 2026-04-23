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

    /// Returns a Process with an enriched PATH covering common Homebrew install locations,
    /// so that GUI app context (which inherits a minimal PATH) can find node/npm.
    static func makeProcess(args: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/usr/local/bin"
        env["PATH"] = [extra, env["PATH"] ?? "/usr/bin:/bin"].joined(separator: ":")
        process.environment = env
        return process
    }
}
