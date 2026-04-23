import SwiftUI
import AppKit

@main
struct SkillsUIApp: App {
    private enum IconStyle {
        static let outerInsetRatio: CGFloat = 0.0625
        static let cornerRadiusRatio: CGFloat = 0.21875
        static let symbolScale: CGFloat = 0.52
        static let shadowBlurRatio: CGFloat = 0.035
        static let shadowOffsetRatio: CGFloat = -0.015

        static let topBlue = NSColor(red: 0.22, green: 0.49, blue: 1.0, alpha: 1.0)
        static let bottomBlue = NSColor(red: 0.06, green: 0.28, blue: 0.95, alpha: 1.0)
        static let glowBlue = NSColor(red: 0.49, green: 0.74, blue: 1.0, alpha: 1.0)
    }

    @State private var skillsManager = SkillsManager()

    init() {
        // SPM executables need explicit activation to show windows
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()

        // Keep a generated icon for raw `swift run` launches.
        if Bundle.main.url(forResource: "AppIcon", withExtension: "icns") == nil {
            NSApplication.shared.applicationIconImage = Self.makeFallbackIcon()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(skillsManager)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 680)
    }

    private static func makeFallbackIcon() -> NSImage {
        let iconSize = NSSize(width: 1024, height: 1024)
        return NSImage(size: iconSize, flipped: false) { rect in
            let inset = rect.width * IconStyle.outerInsetRatio
            let iconRect = rect.insetBy(dx: inset, dy: inset)
            let cornerRadius = rect.width * IconStyle.cornerRadiusRatio

            let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
            shadow.shadowBlurRadius = rect.width * IconStyle.shadowBlurRatio
            shadow.shadowOffset = NSSize(width: 0, height: rect.width * IconStyle.shadowOffsetRatio)
            shadow.set()
            let gradient = NSGradient(colors: [IconStyle.glowBlue, IconStyle.topBlue, IconStyle.bottomBlue])!
            gradient.draw(in: iconPath, angle: -90)
            NSShadow().set()

            NSColor.white.withAlphaComponent(0.18).setStroke()
            iconPath.lineWidth = max(1, rect.width * 0.007)
            iconPath.stroke()

            let config = NSImage.SymbolConfiguration(pointSize: rect.width * IconStyle.symbolScale, weight: .black)
            if let symbol = NSImage(systemSymbolName: "puzzlepiece.extension.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) {
                let symbolSize = symbol.size
                let origin = NSPoint(
                    x: (rect.width - symbolSize.width) / 2,
                    y: (rect.height - symbolSize.height) / 2 + rect.width * 0.01
                )
                let tinted = symbol.copy() as! NSImage
                tinted.lockFocus()
                NSColor.white.set()
                NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
                tinted.unlockFocus()

                let symbolShadow = NSShadow()
                symbolShadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
                symbolShadow.shadowBlurRadius = rect.width * 0.01
                symbolShadow.shadowOffset = NSSize(width: 0, height: -rect.width * 0.004)
                symbolShadow.set()
                tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
                NSShadow().set()
            }

            return true
        }
    }
}
