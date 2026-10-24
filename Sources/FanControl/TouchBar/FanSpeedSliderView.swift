import AppKit

/// Pill-shaped slider like the system volume one: small and large fan on each side,
/// rounded track and white knob. Drag with a finger from anywhere on the track.
final class FanSpeedSliderView: NSView {
    private static let size = NSSize(width: 300, height: 30)
    private static let iconWidth: CGFloat = 26
    private static let trackHeight: CGFloat = 6
    private static let knobDiameter: CGFloat = 22

    /// Called on tap or drag with the new fraction (0...1).
    var onChange: ((Double) -> Void)?
    /// Fills with the accent color (manual) or gray (automatic, only shows the real speed).
    var isActive = false { didSet { needsDisplay = true } }
    private(set) var fraction = 0.5

    private let minimumIcon = FanSpeedSliderView.icon("fan", size: 12)
    private let maximumIcon = FanSpeedSliderView.icon("fan.fill", size: 17)

    init() {
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        allowedTouchTypes = .direct
        addSubview(minimumIcon)
        addSubview(maximumIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("FanSpeedSliderView is not used from Interface Builder")
    }

    override var intrinsicContentSize: NSSize {
        Self.size
    }

    func setFraction(_ value: Double) {
        fraction = min(max(value, 0), 1)
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        minimumIcon.frame = NSRect(x: 0, y: 0, width: Self.iconWidth, height: bounds.height)
        maximumIcon.frame = NSRect(x: bounds.maxX - Self.iconWidth, y: 0, width: Self.iconWidth, height: bounds.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = trackRect
        let knobX = track.minX + track.width * fraction

        NSColor.white.withAlphaComponent(0.22).setFill()
        NSBezierPath(roundedRect: track, xRadius: track.height / 2, yRadius: track.height / 2).fill()

        var filled = track
        filled.size.width = knobX - track.minX
        (isActive ? NSColor.controlAccentColor : NSColor.white.withAlphaComponent(0.55)).setFill()
        NSBezierPath(roundedRect: filled, xRadius: track.height / 2, yRadius: track.height / 2).fill()

        let knob = NSRect(x: knobX - Self.knobDiameter / 2, y: bounds.midY - Self.knobDiameter / 2,
                          width: Self.knobDiameter, height: Self.knobDiameter)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knob).fill()
    }

    override func touchesBegan(with event: NSEvent) {
        follow(event)
    }

    override func touchesMoved(with event: NSEvent) {
        follow(event)
    }

    /// The track keeps half a knob diameter of margin so it does not overlap the icons.
    private var trackRect: NSRect {
        let inset = Self.iconWidth + Self.knobDiameter / 2
        return NSRect(x: inset, y: bounds.midY - Self.trackHeight / 2,
                      width: bounds.width - inset * 2, height: Self.trackHeight)
    }

    private func follow(_ event: NSEvent) {
        guard let touch = event.touches(matching: .touching, in: self).first else { return }
        let track = trackRect
        setFraction(Double((touch.location(in: self).x - track.minX) / track.width))
        onChange?(fraction)
    }

    private static func icon(_ name: String, size: CGFloat) -> NSImageView {
        let view = NSImageView()
        view.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        view.symbolConfiguration = .init(pointSize: size, weight: .medium)
        view.contentTintColor = .secondaryLabelColor
        return view
    }
}
