import AppKit

/// Claude logo (Simple Icons) painted in its orange #D97757.
enum ClaudeLogo {
    static let color = NSColor(srgbRed: 0xD9 / 255, green: 0x77 / 255, blue: 0x57 / 255, alpha: 1)

    static func image(side: CGFloat) -> NSImage? {
        guard let url = Bundle.main.url(forResource: "claude", withExtension: "svg"),
              let source = NSImage(contentsOf: url) else { return nil }
        return NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            source.draw(in: rect)
            color.set()
            rect.fill(using: .sourceIn)
            return true
        }
    }
}
