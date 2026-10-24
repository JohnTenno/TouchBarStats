import AppKit

/// Progress ring with the Claude logo in the center: the outer ring is the weekly limit
/// and the inner one (optional, thinner) the current session. Line width scales with size.
final class ClaudeRingView: NSView {
    var weeklyRemaining: Double? { didSet { needsDisplay = true } }
    var sessionRemaining: Double? { didSet { needsDisplay = true } }
    private let logo: NSImage?
    private let showsSession: Bool
    private let logoScale: CGFloat

    init(logo: NSImage?, side: CGFloat, showsSession: Bool) {
        self.logo = logo
        self.showsSession = showsSession
        self.logoScale = showsSession ? 0.36 : 0.5
        super.init(frame: NSRect(x: 0, y: 0, width: side, height: side))
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draw(_ dirtyRect: NSRect) {
        let side = min(bounds.width, bounds.height)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let outerWidth = max(2.5, side * (showsSession ? 0.1 : 0.12))
        let outerRadius = side / 2 - outerWidth / 2
        drawRing(center: center, radius: outerRadius, width: outerWidth, remaining: weeklyRemaining)

        if showsSession {
            let innerWidth = max(1.5, outerWidth * 0.5)
            let innerRadius = outerRadius - outerWidth / 2 - side * 0.04 - innerWidth / 2
            drawRing(center: center, radius: innerRadius, width: innerWidth, remaining: sessionRemaining)
        }

        let logoSide = side * logoScale
        logo?.draw(in: NSRect(x: center.x - logoSide / 2, y: center.y - logoSide / 2,
                              width: logoSide, height: logoSide))
    }

    private func drawRing(center: NSPoint, radius: CGFloat, width: CGFloat, remaining: Double?) {
        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = width
        NSColor.white.withAlphaComponent(0.15).setStroke()
        track.stroke()

        guard let remaining, remaining > 0 else { return }
        let fraction = CGFloat(min(remaining, 100) / 100)
        let arc = NSBezierPath()
        // Starts at 12 o'clock and goes clockwise.
        arc.appendArc(withCenter: center, radius: radius, startAngle: 90,
                      endAngle: 90 - 360 * fraction, clockwise: true)
        arc.lineWidth = width
        arc.lineCapStyle = .round
        RemainingLevel(remainingPercent: remaining).color.setStroke()
        arc.stroke()
    }
}
