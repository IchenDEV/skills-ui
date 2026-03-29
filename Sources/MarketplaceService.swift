import Foundation

actor MarketplaceService {
    static let shared = MarketplaceService()

    func search(query: String, limit: Int = 20) async throws -> [MarketplaceSkill] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://skills.sh/api/search?q=\(encoded)&limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SkillsShResponse.self, from: data)
        return response.skills.map { skill in
            MarketplaceSkill(
                id: "skillssh-\(skill.id)",
                name: skill.name,
                description: "",
                source: skill.source,
                installs: skill.installs,
                stars: nil,
                author: skill.source.components(separatedBy: "/").first,
                authorAvatar: nil,
                githubUrl: "https://github.com/\(skill.source)",
                marketplace: .skillsSh
            )
        }
    }
}

// MARK: - Response types

private struct SkillsShResponse: Codable {
    let skills: [SkillsShSkill]
}

private struct SkillsShSkill: Codable {
    let id: String
    let name: String
    let installs: Int
    let source: String
}
