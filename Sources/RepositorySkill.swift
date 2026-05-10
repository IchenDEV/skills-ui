import Foundation

struct RepositorySkill: Identifiable, Hashable, Sendable {
    let name: String
    let description: String

    var id: String { name }
}
