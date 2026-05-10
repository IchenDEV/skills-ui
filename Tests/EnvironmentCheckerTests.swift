import XCTest
@testable import SkillsUI

final class EnvironmentCheckerTests: XCTestCase {
    func testMakeProcessAddsUserNodeManagerBinsWhenShellPathIsMinimal() {
        let process = EnvironmentChecker.makeProcess(args: ["node", "--version"])
        let path = process.environment?["PATH"] ?? ""
        let entries = path.split(separator: ":").map(String.init)

        XCTAssertTrue(entries.contains("\(NSHomeDirectory())/n/bin"))
        XCTAssertTrue(entries.contains("\(NSHomeDirectory())/.n/bin"))
        XCTAssertTrue(entries.contains("\(NSHomeDirectory())/.volta/bin"))
        XCTAssertTrue(entries.contains("\(NSHomeDirectory())/.local/bin"))
    }

    func testCommandSearchPathPrefersLoginShellPathEntries() {
        let dynamicNodeBin = "\(NSHomeDirectory())/.custom-node/bin"
        let path = EnvironmentChecker.commandSearchPath(
            existingPath: "/usr/bin:/bin",
            loginShellPath: "\(dynamicNodeBin):/opt/homebrew/bin:/usr/bin:/bin"
        )
        let entries = path.split(separator: ":").map(String.init)

        XCTAssertTrue(entries.contains(dynamicNodeBin))
        XCTAssertLessThan(
            entries.firstIndex(of: dynamicNodeBin)!,
            entries.firstIndex(of: "\(NSHomeDirectory())/n/bin")!
        )
    }
}
