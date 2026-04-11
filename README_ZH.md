<p align="center">
  <img src="assets/icon.svg" width="80" alt="SkillsUI 图标" />
</p>

<h1 align="center">SkillsUI</h1>

<p align="center">
  <strong>一款原生 macOS 应用，用于管理 AI 编程助手的技能包 — 浏览、安装并将 <a href="https://skills.sh">skills.sh</a> 上的技能分发到你所有的 Coding Agent。</strong>
</p>

<p align="center">
  <a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6" /></a>
  <a href="https://developer.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-26+-000?logo=apple&logoColor=white" alt="macOS 26+" /></a>
  <a href="https://developer.apple.com/xcode/swiftui/"><img src="https://img.shields.io/badge/SwiftUI-Framework-007AFF?logo=swift&logoColor=white" alt="SwiftUI" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License" /></a>
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#快速开始">快速开始</a> •
  <a href="#项目结构">项目结构</a> •
  <a href="#支持的-agent">支持的 Agent</a> •
  <a href="README.md">English</a>
</p>

---

## 功能特性

| | 功能 | 说明 |
|---|---|---|
| 🧩 | **技能浏览器** | 查看所有已安装的全局技能，包含丰富的元数据、来源信息和渲染后的 SKILL.md |
| 🔍 | **应用内搜索** | 直接在 App 内搜索 [skills.sh](https://skills.sh)，一键安装 |
| 🤖 | **多 Agent 支持** | 支持向 20+ 个 Agent 安装技能 — Claude Code、Cursor、Codex、Windsurf、Gemini CLI 等 |
| 📂 | **快捷操作** | 在 Finder 中打开、跳转 GitHub、查看源码、移除技能 |
| 🔗 | **符号链接感知** | 自动检测并展示技能是符号链接还是拷贝 |
| 🏷️ | **智能分组** | 按来源仓库自动分组，配以语境化图标 |
| 🛠️ | **引导式安装** | 首次启动时检测 Node.js 与 skills CLI；如有缺失，提供分步安装引导 |
| ⚙️ | **设置与版本管理** | 设置窗口（⌘,）展示运行时版本、检查 skills CLI 更新，并提供一键升级 |

## 快速开始

### 前置条件

- **macOS 26**（Tahoe）或更高版本
- **Swift 6.2+** 工具链（随 Xcode 26+ 附带）
- **Node.js** — 若首次启动时未检测到，SkillsUI 会引导你完成安装

> **提示：** 无需手动安装 skills CLI。SkillsUI 会在启动引导和**设置 → 运行环境**页面中检测并提供安装指引。

### 构建并运行

```bash
# 克隆项目
git clone https://github.com/IchenDEV/skills-ui.git
cd skills-ui

# 构建
swift build

# 运行
swift run SkillsUI
```

### Release 构建

```bash
swift build -c release
cp .build/release/SkillsUI /usr/local/bin/
```

> **注意：** 本地构建的二进制文件未经签名。若 macOS 阻止运行，执行一次 `xattr -cr SkillsUI` 清除隔离标志即可。

### 下载预构建二进制

每个 [GitHub Release](https://github.com/IchenDEV/skills-ui/releases) 都附带已构建好的 arm64 二进制文件及 `.sha256` 校验文件。

```bash
# 下载后验证校验和
shasum -a 256 -c SkillsUI-*.tar.gz.sha256
```

## 项目结构

```
Sources/
├── SkillsUIApp.swift          # @main 入口，窗口配置，应用图标，Settings 场景
├── ContentView.swift           # TabView（已安装 / 应用市场）+ 引导触发
├── SkillsSidebar.swift         # 侧栏列表，按来源分组，底部版本角标
├── SkillDetailView.swift       # 详情面板 — 元数据网格 + SKILL.md
├── AddSkillSheet.swift         # 从 GitHub 添加技能的弹窗
├── MarketplaceView.swift       # 应用市场搜索界面
├── MarketplaceService.swift    # skills.sh API 客户端（actor）
├── MarketplaceSkill.swift      # 市场数据模型
├── SkillsManager.swift         # 核心状态管理 — 扫描、安装、移除、环境检查
├── Skill.swift                 # 已安装技能模型
├── Skill+UI.swift              # SwiftUI 扩展：skillColor
├── SkillParser.swift           # SKILL.md YAML frontmatter 解析器
├── SkillLock.swift             # .skill-lock.json Codable 类型
├── DependencyChecker.swift     # DependencyStatus 模型 + EnvironmentChecker
├── OnboardingView.swift        # 缺少 Node / skills CLI 时显示的安装引导弹窗
├── SettingsView.swift          # 设置窗口（关于 + 运行环境 两个标签页）
└── AppVersion.swift            # 版本字符串 — Release 构建时由 CI 覆写
```

### 设计理念

- **SwiftPM 可执行文件** — 无需 Xcode 项目，`swift build` 即可构建
- **`@Observable` + actor** — 全面采用 Swift 6 严格并发
- **零第三方 UI 依赖** — 纯 SwiftUI，原生 macOS 风格
- **构建时注入版本号** — CI 在 `swift build -c release` 之前将 Release Tag 写入 `AppVersion.swift`，确保**设置 → 关于**中始终显示正确版本

## 发布新版本

推送符合 `v*` 格式的 Tag，CI 工作流将自动构建二进制文件并上传到对应的 GitHub Release：

```bash
git tag v1.2.3
git push origin v1.2.3
```

## 工作原理

```
┌──────────────┐     npx skills add     ┌──────────────────┐
│  skills.sh   │ ◄──────────────────── │    SkillsUI      │
│  应用市场     │                        │  （本应用）       │
└──────┬───────┘                        └────────┬─────────┘
       │                                         │
       │  下载                            扫描 & 解析
       ▼                                         ▼
┌──────────────┐     符号链接            ┌──────────────────┐
│ ~/.agents/   │ ────────────────────► │ ~/.cursor/skills  │
│   skills/    │                        │ ~/.claude/skills  │
│              │                        │ ~/.codex/skills   │
│  SKILL.md    │                        │   ...             │
│  lock.json   │                        └──────────────────┘
└──────────────┘
```

## 支持的 Agent

| Agent | 技能路径 |
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

## 贡献

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/awesome`）
3. 提交改动（`git commit -m 'Add awesome feature'`）
4. 推送分支（`git push origin feature/awesome`）
5. 发起 Pull Request

## 许可证

本项目采用 MIT 许可证 — 详见 [LICENSE](LICENSE) 文件。

---

<p align="center">
  用 ❤️ 和 SwiftUI 构建
</p>
