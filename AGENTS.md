# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build debug
swift build

# Run
swift run SkillsUI

# Build release
swift build -c release
```

There are no tests in this project. Type-check only:
```bash
swift build 2>&1 | head -50
```

## Requirements

- macOS 26 (Tahoe) / Swift 6.2+ (Xcode 26+)
- `npx skills` CLI installed globally (`npm i -g skills`) — required at runtime for install/remove/update operations

## Architecture

**SwiftPM executable** targeting macOS 26, Swift 6 strict concurrency. Direct Markdown rendering dependency: `Textual`, used for native block-level `SKILL.md` previews.

### Data flow

```
~/.agents/.skill-lock.json   ──► SkillsManager.loadLockFile()  ──► SkillLockEntry
~/.agents/skills/*/SKILL.md  ──► SkillParser.parse()           ──► Skill model
~/.{agent}/skills/           ──► SkillsManager.detectAgentLinks() ──► [agentName]
```

`SkillsManager` (`@Observable @MainActor`) is the single source of truth, injected via SwiftUI environment. All filesystem work runs in `Task.detached` for Swift 6 sendability. The app calls `npx skills` CLI for install/remove/update operations (via `Process`).

### Key files

| File | Role |
|---|---|
| `SkillsUIApp.swift` | `@main`, window setup, programmatic app icon |
| `ContentView.swift` | `TabView` with Installed + Marketplace tabs |
| `SkillsManager.swift` | Core state — scanning `~/.agents/skills`, symlink detection, npx delegation |
| `Skill.swift` | Installed skill value type |
| `SkillParser.swift` | YAML frontmatter parser for `SKILL.md` files (only `name:` and `description:`) |
| `SkillMarkdownView.swift` | Native `Textual` renderer with local heading / quote / code block styling |
| `SkillLock.swift` | Codable types for `~/.agents/.skill-lock.json` |
| `MarketplaceService.swift` | `actor` — calls `https://skills.sh/api/search` |
| `MarketplaceSkill.swift` | Marketplace result model |
| `SkillsSidebar.swift` | Sidebar grouped by `source` repo |
| `SkillDetailView.swift` | Detail pane with metadata grid + rendered Markdown |
| `AddSkillSheet.swift` | Sheet for adding skills by GitHub source string |
| `MarketplaceView.swift` | Marketplace search UI |

### Skill storage layout

- **Global store**: `~/.agents/skills/<skill-name>/SKILL.md`
- **Lock file**: `~/.agents/.skill-lock.json` (tracks source, install dates)
- **Agent links**: `~/.{agent}/skills/<skill-name>` — symlinks back to global store
- `SkillsManager.allAgents` is the authoritative list of 20 supported agents and their paths

### Concurrency model

Swift 6 strict concurrency. `SkillsManager` is `@MainActor`. Static scanning helpers are `nonisolated` and run inside `Task.detached`. `MarketplaceService` is an `actor` singleton. Do not access UI state from detached tasks.
