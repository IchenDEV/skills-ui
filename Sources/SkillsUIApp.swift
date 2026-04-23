import SwiftUI
import AppKit

@main
struct SkillsUIApp: App {
    @State private var skillsManager = SkillsManager()

    init() {
        // SPM executables need explicit activation to show windows
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()

        // Create a custom app icon so the README logo and runtime icon stay aligned.
        let iconSize = NSSize(width: 1024, height: 1024)
        let iconImage = NSImage(size: iconSize, flipped: false) { rect in
            let inset: CGFloat = 100
            let plateRect = rect.insetBy(dx: inset, dy: inset)
            let cornerRadius: CGFloat = 185

            let platePath = NSBezierPath(roundedRect: plateRect, xRadius: cornerRadius, yRadius: cornerRadius)
            let plateShadow = NSShadow()
            plateShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
            plateShadow.shadowBlurRadius = 28
            plateShadow.shadowOffset = NSSize(width: 0, height: -10)
            plateShadow.set()

            let plateGradient = NSGradient(colorsAndLocations:
                (NSColor(srgbRed: 1.0, green: 0.976, blue: 0.933, alpha: 1.0), 0.0),
                (NSColor(srgbRed: 0.933, green: 0.969, blue: 0.98, alpha: 1.0), 1.0)
            )
            plateGradient?.draw(in: platePath, angle: -90)
            NSShadow().set()

            NSColor(srgbRed: 0.843, green: 0.89, blue: 0.918, alpha: 1.0).setStroke()
            platePath.lineWidth = 10
            platePath.stroke()

            func fillRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
                color.setFill()
                NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            }

            func strokeRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor, width: CGFloat) {
                let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
                path.lineWidth = width
                color.setStroke()
                path.stroke()
            }

            func drawCard(_ rect: NSRect, fillColor: NSColor, strokeColor: NSColor, accentColor: NSColor) {
                let cardShadow = NSShadow()
                cardShadow.shadowColor = NSColor.black.withAlphaComponent(0.08)
                cardShadow.shadowBlurRadius = 12
                cardShadow.shadowOffset = NSSize(width: 0, height: -4)
                cardShadow.set()
                fillRoundedRect(rect, radius: 48, color: fillColor)
                NSShadow().set()

                strokeRoundedRect(rect, radius: 48, color: strokeColor, width: 6)

                let accentRect = NSRect(
                    x: rect.minX + 54,
                    y: rect.midY - 36,
                    width: 58,
                    height: 72
                )
                fillRoundedRect(accentRect, radius: 28, color: accentColor)

                fillRoundedRect(
                    NSRect(x: rect.minX + 144, y: rect.midY + 10, width: 176, height: 24),
                    radius: 12,
                    color: NSColor(srgbRed: 0.09, green: 0.19, blue: 0.26, alpha: 0.22)
                )
                fillRoundedRect(
                    NSRect(x: rect.minX + 144, y: rect.midY - 28, width: 124, height: 24),
                    radius: 12,
                    color: NSColor(srgbRed: 0.09, green: 0.19, blue: 0.26, alpha: 0.14)
                )
            }

            let backCard = NSRect(x: plateRect.minX + 120, y: plateRect.maxY - 270, width: 410, height: 180)
            let middleCard = NSRect(x: plateRect.minX + 200, y: plateRect.maxY - 430, width: 452, height: 180)
            let frontCard = NSRect(x: plateRect.minX + 280, y: plateRect.maxY - 590, width: 410, height: 180)

            drawCard(
                backCard,
                fillColor: NSColor(srgbRed: 0.875, green: 0.961, blue: 0.918, alpha: 1.0),
                strokeColor: NSColor(srgbRed: 0.776, green: 0.906, blue: 0.859, alpha: 1.0),
                accentColor: NSColor(srgbRed: 0.122, green: 0.616, blue: 0.463, alpha: 1.0)
            )
            drawCard(
                middleCard,
                fillColor: NSColor(srgbRed: 0.867, green: 0.922, blue: 1.0, alpha: 1.0),
                strokeColor: NSColor(srgbRed: 0.78, green: 0.852, blue: 0.961, alpha: 1.0),
                accentColor: NSColor(srgbRed: 0.231, green: 0.51, blue: 0.965, alpha: 1.0)
            )
            drawCard(
                frontCard,
                fillColor: NSColor(srgbRed: 1.0, green: 0.969, blue: 0.91, alpha: 1.0),
                strokeColor: NSColor(srgbRed: 0.941, green: 0.871, blue: 0.757, alpha: 1.0),
                accentColor: NSColor(srgbRed: 0.961, green: 0.62, blue: 0.043, alpha: 1.0)
            )

            let badgeRect = NSRect(x: plateRect.maxX - 214, y: plateRect.maxY - 214, width: 132, height: 132)
            fillRoundedRect(badgeRect, radius: 66, color: NSColor(srgbRed: 0.059, green: 0.463, blue: 0.431, alpha: 1.0))

            let sparkleCenter = NSPoint(x: badgeRect.midX, y: badgeRect.midY)
            let sparklePath = NSBezierPath()
            sparklePath.move(to: NSPoint(x: sparkleCenter.x, y: sparkleCenter.y + 34))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x + 12, y: sparkleCenter.y + 12))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x + 34, y: sparkleCenter.y))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x + 12, y: sparkleCenter.y - 12))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x, y: sparkleCenter.y - 34))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x - 12, y: sparkleCenter.y - 12))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x - 34, y: sparkleCenter.y))
            sparklePath.line(to: NSPoint(x: sparkleCenter.x - 12, y: sparkleCenter.y + 12))
            sparklePath.close()
            NSColor(srgbRed: 1.0, green: 0.969, blue: 0.839, alpha: 1.0).setFill()
            sparklePath.fill()

            if let shine = NSGradient(colorsAndLocations:
                (NSColor.white.withAlphaComponent(0.22), 0.0),
                (NSColor.white.withAlphaComponent(0.0), 1.0)
            ) {
                let shineRect = NSRect(x: plateRect.minX + 34, y: plateRect.maxY - 150, width: 280, height: 92)
                let shinePath = NSBezierPath(roundedRect: shineRect, xRadius: 34, yRadius: 34)
                shine.draw(in: shinePath, angle: -90)
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

        Settings {
            SettingsView()
                .environment(skillsManager)
        }
    }
}
