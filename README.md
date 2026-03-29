<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="80" alt="SkillsUI Icon" />
</p>

<h1 align="center">SkillsUI</h1>

<p align="center">
  <strong>A native macOS app to manage AI agent skills — browse, install, and organize <a href="https://skills.sh">skills.sh</a> packages across all your coding agents.</strong>
</p>

<p align="center">
  <a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6" /></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-26+-000?logo=apple&logoColor=white" alt="macOS 26+" /></a>
  <a href="https://developer.apple.com/xcode/swiftui/"><img src="https://img.shields.io/badge/SwiftUI-Framework-007AFF?logo=swift&logoColor=white" alt="SwiftUI" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License" /></a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#supported-agents">Supported Agents</a> •
  <a href="README_ZH.md">中文文档</a>
</p>

---

## Features

| | Feature | Description |
|---|---|---|
| 🧩 | **Skill Browser** | View all globally installed skills with rich metadata, source info, and rendered SKILL.md content |
| 🔍 | **Marketplace Search** | Search [skills.sh](https://skills.sh) directly from the app and install with one click |
| 🤖 | **Multi-Agent Support** | Install skills to 20+ agents — Claude Code, Cursor, Codex, Windsurf, Gemini CLI, and more |
| 📂 | **Quick Actions** | Reveal in Finder, open on GitHub, view raw source, or remove skills instantly |
| 🔗 | **Symlink Aware** | Detects and displays whether skills are symlinks or copies |
| 🏷️ | **Smart Grouping** | Auto-groups skills by source repository with contextual icons |

## Screenshots

> _Build and run the app to see the full UI — a `NavigationSplitView` with sidebar + detail, plus a Marketplace tab._

## Getting Started

### Prerequisites

- **macOS 26** (Tahoe) or later
- **Swift 6.2+** toolchain (ships with Xcode 26+)
- [`npx skills`](https://skills.sh) CLI installed globally (`npm i -g skills`)

### Build & Run

```bash
# Clone
git clone https://github.com/IchenDEV/skills-ui.git
cd skills-ui

# Build
swift build

# Run
swift run SkillsUI
# — or —
open .build/debug/SkillsUI
```

### Build for Release

```bash
swift build -c release
cp .build/release/SkillsUI /usr/local/bin/
```

## Architecture

```
Sources/
├── SkillsUIApp.swift          # @main entry, window config, app icon
├── ContentView.swift           # TabView (Installed / Marketplace)
├── SkillsSidebar.swift         # Sidebar list, grouped by source
├── SkillDetailView.swift       # Detail pane — metadata grid + SKILL.md
├── AddSkillSheet.swift         # Sheet for adding skills from GitHub
├── MarketplaceView.swift       # Marketplace search UI
├── MarketplaceService.swift    # skills.sh API client (actor)
├── MarketplaceSkill.swift      # Marketplace data model
├── SkillsManager.swift         # Core state — scanning, install, remove
├── Skill.swift                 # Installed skill model
├── SkillParser.swift           # SKILL.md YAML frontmatter parser
└── SkillLock.swift             # .skill-lock.json Codable types
```

### Key Design Decisions

- **SwiftPM executable** — no Xcode project required; builds with `swift build`
- **`@Observable` + actors** — Swift 6 strict concurrency throughout
- **No third-party UI deps** — pure SwiftUI with native macOS look & feel
- **`swift-markdown`** — only dependency, used for Markdown rendering

## Supported Agents

SkillsUI can install and detect skills for the following AI coding agents:

| Agent | Skills Path |
|---|---|
| Amp | `~/.agents/skills` |
| Claude Code | `~/.claude/skills` |
| Codex | `~/.codex/skills` |
| Cursor | `~/.cursor/skills` |
| Windsurf | `~/.codeium/windsurf/skills` |
| Gemini CLI | `~/.gemini/skills` |
| GitHub Copilot | `~/.copilot/skills` |
| Roo Code | `~/.roo/skills` |
| Cline | `~/.cline/skills` |
| OpenCode | `~/.config/opencode/skills` |
| Trae | `~/.trae/skills` |
| Augment | `~/.augment/skills` |
| Droid | `~/.factory/skills` |
| Kiro | `~/.kiro/skills` |
| Warp | `~/.warp/skills` |
| Deep Agents | `~/.deepagents/agent/skills` |
| Antigravity | `~/.gemini/antigravity/skills` |
| OpenHands | `~/.openhands/skills` |
| Qwen Code | `~/.qwen/skills` |
| Trae CN | `~/.trae-cn/skills` |

## How It Works

```
┌──────────────┐     npx skills add     ┌──────────────────┐
│  skills.sh   │ ◄──────────────────── │    SkillsUI      │
│  Marketplace │                        │  (this app)      │
└──────┬───────┘                        └────────┬─────────┘
       │                                         │
       │  download                     scan & parse
       ▼                                         ▼
┌──────────────┐     symlink            ┌──────────────────┐
│ ~/.agents/   │ ────────────────────► │ ~/.cursor/skills  │
│   skills/    │                        │ ~/.claude/skills  │
│              │                        │ ~/.codex/skills   │
│  SKILL.md    │                        │   ...             │
│  lock.json   │                        └──────────────────┘
└──────────────┘
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to the branch (`git push origin feature/awesome`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ and SwiftUI
</p>
