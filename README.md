<p align="center">
  <img src="assets/icon.svg" width="80" alt="SkillsUI Icon" />
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
| 🛠️ | **Guided Setup** | Detects Node.js and skills CLI on launch; walks you through installation if anything is missing |
| ⚙️ | **Settings & Versioning** | Settings window (⌘,) shows runtime versions, checks for skills CLI updates, and offers one-click upgrade |

## Getting Started

### Prerequisites

- **macOS 26** (Tahoe) or later
- **Swift 6.2+** toolchain (ships with Xcode 26+)
- **Node.js** — SkillsUI will guide you through installation on first launch if it's missing

> **Tip:** You don't need to install the skills CLI manually. SkillsUI detects whether it's present and offers installation guidance in the onboarding sheet and in **Settings → Environment**.

### Build & Run

```bash
# Clone
git clone https://github.com/IchenDEV/skills-ui.git
cd skills-ui

# Build
swift build

# Run
swift run SkillsUI
```

### Build for Release

```bash
swift build -c release
cp .build/release/SkillsUI /usr/local/bin/
```

> **Note:** Binaries built locally are unsigned. If macOS blocks the app, run `xattr -cr SkillsUI` once to clear the quarantine flag.

### Download a Pre-built Binary

Pre-built binaries (arm64) are attached to every [GitHub Release](https://github.com/IchenDEV/skills-ui/releases). Each release includes a `.sha256` checksum file for verification.

```bash
# Verify checksum after download
shasum -a 256 -c SkillsUI-*.tar.gz.sha256
```

## Architecture

```
Sources/
├── SkillsUIApp.swift          # @main entry, window config, app icon, Settings scene
├── ContentView.swift           # TabView (Installed / Marketplace) + onboarding trigger
├── SkillsSidebar.swift         # Sidebar list, grouped by source, version footer
├── SkillDetailView.swift       # Detail pane — metadata grid + SKILL.md
├── AddSkillSheet.swift         # Sheet for adding skills from GitHub
├── MarketplaceView.swift       # Marketplace search UI
├── MarketplaceService.swift    # skills.sh API client (actor)
├── MarketplaceSkill.swift      # Marketplace data model
├── SkillsManager.swift         # Core state — scanning, install, remove, env check
├── Skill.swift                 # Installed skill model
├── Skill+UI.swift              # SwiftUI extension: skillColor
├── SkillParser.swift           # SKILL.md YAML frontmatter parser
├── SkillLock.swift             # .skill-lock.json Codable types
├── DependencyChecker.swift     # DependencyStatus model + EnvironmentChecker
├── OnboardingView.swift        # Setup sheet shown when Node/skills CLI is missing
├── SettingsView.swift          # Settings window (About + Environment tabs)
└── AppVersion.swift            # Version string — overwritten by CI on release builds
```

### Key Design Decisions

- **SwiftPM executable** — no Xcode project required; builds with `swift build`
- **`@Observable` + actors** — Swift 6 strict concurrency throughout
- **No third-party UI deps** — pure SwiftUI with native macOS look & feel
- **Version baked at build time** — CI overwrites `AppVersion.swift` with the Release tag before `swift build -c release`

## Supported Agents

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

## Releasing a New Version

Push a tag matching `v*` and the CI workflow builds the binary and attaches it to the GitHub Release automatically:

```bash
git tag v1.2.3
git push origin v1.2.3
```

The workflow injects the tag version into `AppVersion.swift` before building, so **Settings → About** always shows the correct release version.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push the branch (`git push origin feature/awesome`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ and SwiftUI
</p>
