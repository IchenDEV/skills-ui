import SwiftUI

enum AppTab: String, CaseIterable {
    case installed = "Installed"
    case marketplace = "Marketplace"

    var icon: String {
        switch self {
        case .installed: "puzzlepiece.extension"
        case .marketplace: "storefront"
        }
    }
}

struct ContentView: View {
    @Environment(SkillsManager.self) private var manager
    @State private var selectedTab: AppTab = .installed
    @State private var selectedSkillID: Skill.ID?
    @State private var searchText = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var selectedSkill: Skill? {
        guard let selectedSkillID else { return nil }
        return manager.skills.first { $0.id == selectedSkillID }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.installed.rawValue, systemImage: AppTab.installed.icon, value: .installed) {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SkillsSidebar(selectedSkillID: $selectedSkillID, searchText: $searchText)
                } detail: {
                    if let skill = selectedSkill {
                        SkillDetailView(skill: skill)
                            .id(skill.renderCacheKey)
                    } else {
                        ContentUnavailableView("Select a Skill", systemImage: "puzzlepiece.extension", description: Text("Choose a skill from the sidebar to view its details."))
                    }
                }
                .searchable(text: $searchText, placement: .sidebar, prompt: "Filter skills")
            }

            Tab(AppTab.marketplace.rawValue, systemImage: AppTab.marketplace.icon, value: .marketplace) {
                NavigationStack {
                    MarketplaceView()
                }
            }
        }
        .task {
            await manager.loadSkills()
        }
    }
}
