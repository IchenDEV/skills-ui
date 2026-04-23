import SwiftUI
import Textual

struct SkillMarkdownView: View {
    let markdown: String
    let baseURL: URL?
    let renderKey: String

    var body: some View {
        Group {
            if markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                GroupBox {
                    Text("No Markdown content to preview.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            } else {
                StructuredText(markdown: markdown, baseURL: baseURL)
                    .id(renderKey)
                    .textual.structuredTextStyle(.default)
                    .textual.headingStyle(SkillMarkdownHeadingStyle())
                    .textual.blockQuoteStyle(SkillMarkdownBlockQuoteStyle())
                    .textual.codeBlockStyle(SkillMarkdownCodeBlockStyle())
                    .textual.overflowMode(.scroll)
                    .textual.textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct SkillMarkdownHeadingStyle: StructuredText.HeadingStyle {
    private static let fontScales: [CGFloat] = [1.9, 1.55, 1.3, 1.15, 1.0, 0.94]

    func makeBody(configuration: Configuration) -> some View {
        let headingLevel = min(configuration.headingLevel, 6)
        let fontScale = Self.fontScales[headingLevel - 1]
        let topSpacing: CGFloat = headingLevel == 1 ? 1.4 : 1.05
        let bottomSpacing: CGFloat = headingLevel <= 2 ? 0.55 : 0.35

        return VStack(alignment: .leading, spacing: 0) {
            configuration.label
                .textual.fontScale(fontScale)
                .textual.lineSpacing(.fontScaled(headingLevel <= 2 ? 0.18 : 0.24))
                .fontWeight(headingLevel <= 2 ? .bold : .semibold)
                .foregroundStyle(.primary)

            if headingLevel == 1 {
                Divider()
                    .padding(.top, 10)
            }
        }
        .textual.blockSpacing(.fontScaled(top: topSpacing, bottom: bottomSpacing))
    }
}

private struct SkillMarkdownBlockQuoteStyle: StructuredText.BlockQuoteStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .textual.lineSpacing(.fontScaled(0.35))
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(.tint.opacity(0.7))
                            .frame(width: 4)
                            .padding(.vertical, 10)
                            .padding(.leading, 8)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.8), lineWidth: 1)
                    }
            }
            .textual.blockSpacing(.fontScaled(top: 0.7, bottom: 0.15))
    }
}

private struct SkillMarkdownCodeBlockStyle: StructuredText.CodeBlockStyle {
    func makeBody(configuration: Configuration) -> some View {
        Overflow {
            configuration.label
                .textual.lineSpacing(.fontScaled(0.28))
                .textual.fontScale(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .monospaced()
                .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.85), lineWidth: 1)
        }
        .textual.blockSpacing(.fontScaled(top: 0.7, bottom: 0.2))
    }
}
