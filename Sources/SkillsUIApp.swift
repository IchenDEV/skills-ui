import SwiftUI
import AppKit

@main
struct SkillsUIApp: App {
    @State private var skillsManager = SkillsManager()

    init() {
        // SPM executables need explicit activation to show windows
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()

        // Create app icon — 1024×1024, white bg, matching standard macOS icon size
        let iconSize = NSSize(width: 1024, height: 1024)
        let iconImage = NSImage(size: iconSize, flipped: false) { rect in
            // macOS icon inset: ~824px centered in 1024 with ~100px margin
            let inset: CGFloat = 100
            let iconRect = rect.insetBy(dx: inset, dy: inset)
            let cornerRadius: CGFloat = 185

            // White background
            NSColor.white.setFill()
            NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()

            // Subtle shadow
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
            shadow.shadowBlurRadius = 20
            shadow.shadowOffset = NSSize(width: 0, height: -8)
            shadow.set()
            NSColor.white.setFill()
            NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            NSShadow().set() // reset

            // Gradient symbol
            let config = NSImage.SymbolConfiguration(pointSize: 380, weight: .medium)
            if let symbol = NSImage(systemSymbolName: "puzzlepiece.extension.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) {
                let symbolSize = symbol.size
                let origin = NSPoint(
                    x: (rect.width - symbolSize.width) / 2,
                    y: (rect.height - symbolSize.height) / 2
                )
                // Draw with blue-purple tint
                let tint = NSColor(red: 0.35, green: 0.35, blue: 0.95, alpha: 1.0)
                let tinted = symbol.copy() as! NSImage
                tinted.lockFocus()
                tint.set()
                NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
                tinted.unlockFocus()
                tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            return true
        }
        NSApplication.shared.applicationIconImage = iconImage
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(skillsManager)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 680)
    }
}
