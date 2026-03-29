import Foundation

enum SkillParser {
    /// Parse SKILL.md frontmatter (YAML between --- delimiters) and body
    static func parse(fileContent: String) -> (name: String?, description: String?, body: String) {
        let lines = fileContent.components(separatedBy: "\n")
        guard lines.first == "---" else {
            return (nil, nil, fileContent)
        }
        
        var name: String?
        var description: String?
        var frontmatterEnd = 0
        
        for i in 1..<lines.count {
            if lines[i] == "---" {
                frontmatterEnd = i
                break
            }
            let line = lines[i]
            if line.hasPrefix("name:") {
                name = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                // Remove quotes if present
                if let n = name, n.hasPrefix("\"") && n.hasSuffix("\"") {
                    name = String(n.dropFirst().dropLast())
                }
            } else if line.hasPrefix("description:") {
                description = line.dropFirst(12).trimmingCharacters(in: .whitespaces)
                if let d = description, d.hasPrefix("\"") && d.hasSuffix("\"") {
                    description = String(d.dropFirst().dropLast())
                }
                // Handle multi-line description (indented continuation)
                var j = i + 1
                while j < lines.count && lines[j] != "---" {
                    let cont = lines[j]
                    if cont.hasPrefix("  ") || cont.hasPrefix("\t") {
                        description = (description ?? "") + " " + cont.trimmingCharacters(in: .whitespaces)
                        j += 1
                    } else {
                        break
                    }
                }
            }
        }
        
        let body: String
        if frontmatterEnd > 0 && frontmatterEnd + 1 < lines.count {
            body = lines[(frontmatterEnd + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            body = fileContent
        }
        
        return (name, description, body)
    }
}
