<p align="center">
  <img src="Packaging/AppIcon.iconset/icon_256x256.png" width="80" alt="SkillsUI Icon" />
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
- **Xcode 26+** (or an equivalent Swift 6.2 toolchain with full macOS UI macro support)
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
./scripts/package-dmg.sh
open dist
```

This creates:

- `dist/SkillsUI.app`
- `dist/SkillsUI.dmg`

Install it like a normal Mac app: open the DMG and drag `SkillsUI.app` into `Applications`.

The current packaging flow is for local distribution and testing. It uses an ad-hoc signature by default, and it does not include Developer ID signing or notarization yet.

If `xcode-select -p` still points at Command Line Tools, the packaging script automatically switches builds to `/Applications/Xcode.app/Contents/Developer` when that Xcode install exists.

## Architecture

```
Sources/
├── SkillsUIApp.swift          # @main entry, window config, app icon
├── ContentView.swift           # TabView (Installed / Marketplace)
├── SkillsSidebar.swift         # Sidebar list, grouped by source
├── SkillDetailView.swift       # Detail pane — metadata grid + SKILL.md
├── SkillMarkdownView.swift     # Native Textual renderer + local markdown styling
├── AddSkillSheet.swift         # Sheet for adding skills from GitHub
├── MarketplaceView.swift       # Marketplace search UI
├── MarketplaceService.swift    # skills.sh API client (actor)
├── MarketplaceSkill.swift      # Marketplace data model
├── SkillsManager.swift         # Core state — scanning, install, remove
├── Skill.swift                 # Installed skill model
├── SkillParser.swift           # SKILL.md YAML frontmatter parser
└── SkillLock.swift             # .skill-lock.json Codable types

Packaging/
├── AppIcon.iconset/            # Source PNGs for the bundled app icon
├── AppIcon.icns                # Bundled app icon used by Finder/Dock
└── Info.plist.template         # App bundle metadata template

scripts/
├── package-dmg.sh              # Builds SkillsUI.app and SkillsUI.dmg
└── render-app-icon.swift       # Regenerates the tracked iconset PNGs
```

### Key Design Decisions

- **SwiftPM executable** — no Xcode project required; builds with `swift build`
- **`@Observable` + actors** — Swift 6 strict concurrency throughout
- **No third-party UI deps** — pure SwiftUI with native macOS look & feel
- **`Textual`** — direct rendering dependency for native, block-level Markdown previews

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
