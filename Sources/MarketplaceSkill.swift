import Foundation

struct MarketplaceSkill: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let source: String
    let installs: Int?
    let stars: Int?
    let author: String?
    let githubUrl: String?
    let marketplace: MarketplaceSource
}

enum MarketplaceSource: String, CaseIterable, Sendable {
    case skillsSh = "skills.sh"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .skillsSh: "sparkles"
        }
    }
}
