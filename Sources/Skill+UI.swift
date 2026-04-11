import SwiftUI

extension Skill {
    var skillColor: Color {
        if name.hasPrefix("ljg-") { return .orange }
        if name.contains("react") { return .cyan }
        if name.contains("design") { return .pink }
        if name.contains("find") { return .blue }
        if name.contains("browser") { return .green }
        if name.contains("vercel") { return .purple }
        if name.contains("dogfood") { return .red }
        if name.contains("a2a") { return .indigo }
        return .gray
    }
}
