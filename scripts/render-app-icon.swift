#!/usr/bin/env swift

import AppKit
import Foundation

struct IconRenderer {
    struct Style {
        static let outerInsetRatio: CGFloat = 0.0625
        static let cornerRadiusRatio: CGFloat = 0.21875
        static let symbolScale: CGFloat = 0.52
        static let shadowBlurRatio: CGFloat = 0.035
        static let shadowOffsetRatio: CGFloat = -0.015
        static let highlightLineRatio: CGFloat = 0.007

        static let topBlue = NSColor(red: 0.22, green: 0.49, blue: 1.0, alpha: 1.0)
        static let bottomBlue = NSColor(red: 0.06, green: 0.28, blue: 0.95, alpha: 1.0)
        static let glowBlue = NSColor(red: 0.49, green: 0.74, blue: 1.0, alpha: 1.0)
    }

    static let outputs: [(name: String, size: CGFloat)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    static func run() throws {
        let fm = FileManager.default
        let repoRoot = URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
        let iconsetURL = repoRoot.appendingPathComponent("Packaging/AppIcon.iconset", isDirectory: true)

        try fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

        for output in outputs {
            let data = try pngData(for: output.size)
            try data.write(to: iconsetURL.appendingPathComponent(output.name), options: .atomic)
        }
    }

    static func pngData(for size: CGFloat) throws -> Data {
        let pixelsWide = Int(size.rounded())
        let pixelsHigh = Int(size.rounded())

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw IconError.bitmapCreationFailed
        }

        rep.size = NSSize(width: size, height: size)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            throw IconError.contextCreationFailed
        }

        NSGraphicsContext.current = context
        context.imageInterpolation = .high

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        rect.fill()

        let inset = size * Style.outerInsetRatio
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let cornerRadius = size * Style.cornerRadiusRatio

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow.shadowBlurRadius = size * Style.shadowBlurRatio
        shadow.shadowOffset = NSSize(width: 0, height: size * Style.shadowOffsetRatio)

        shadow.set()
        let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
        let gradient = NSGradient(colors: [Style.glowBlue, Style.topBlue, Style.bottomBlue])!
        gradient.draw(in: iconPath, angle: -90)
        NSShadow().set()

        NSColor.white.withAlphaComponent(0.18).setStroke()
        iconPath.lineWidth = max(1, size * Style.highlightLineRatio)
        iconPath.stroke()

        let config = NSImage.SymbolConfiguration(pointSize: size * Style.symbolScale, weight: .black)
        if let symbol = NSImage(systemSymbolName: "puzzlepiece.extension.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            let symbolSize = symbol.size
            let symbolRect = NSRect(
                x: (size - symbolSize.width) / 2,
                y: (size - symbolSize.height) / 2 + size * 0.01,
                width: symbolSize.width,
                height: symbolSize.height
            )

            let tinted = symbol.copy() as! NSImage
            tinted.lockFocus()
            NSColor.white.set()
            NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
            tinted.unlockFocus()

            let symbolShadow = NSShadow()
            symbolShadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
            symbolShadow.shadowBlurRadius = size * 0.01
            symbolShadow.shadowOffset = NSSize(width: 0, height: -size * 0.004)
            symbolShadow.set()
            tinted.draw(in: symbolRect)
            NSShadow().set()
        }

        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw IconError.pngEncodingFailed
        }

        return data
    }
}

enum IconError: Error {
    case bitmapCreationFailed
    case contextCreationFailed
    case pngEncodingFailed
}

do {
    try IconRenderer.run()
} catch {
    fputs("Failed to render app icon: \(error)\n", stderr)
    exit(1)
}
