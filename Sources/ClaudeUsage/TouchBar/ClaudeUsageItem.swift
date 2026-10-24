import AppKit

/// Compact Claude badge (logo + weekly % remaining) that opens its own bar when tapped, like the fan:
/// weekly/session ring, time left until the weekly reset and the current session.
final class ClaudeUsageItem: NSObject, ClaudeUsageObserver {
    private static let buttonIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.claude")
    private static let ringIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.claudeRing")
    private static let weeklyIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.claudeWeekly")
    private static let sessionIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.claudeSession")
    private static let refreshIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.claudeRefresh")
    private static let fontSize: CGFloat = 13

    weak var delegate: ClaudeUsageItemDelegate?
    let buttonItem = NSCustomTouchBarItem(identifier: ClaudeUsageItem.buttonIdentifier)
    let touchBar = NSTouchBar()
    private lazy var badge = ClaudeBadgeView(fontSize: Self.fontSize) { [weak self] in self?.open() }
    private let ring = ClaudeRingView(logo: ClaudeLogo.image(side: 64), side: 28, showsSession: true)
    private let weeklyLabel = NSTextField(labelWithString: "Loading…")
    private let sessionLabel = NSTextField(labelWithString: "")
    private let onRefresh: () -> Void

    init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
        super.init()
        buttonItem.view = badge

        let refreshButton = NSButton(image: NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh") ?? NSImage(),
                                     target: self, action: #selector(refresh))
        touchBar.templateItems = [makeItem(Self.ringIdentifier, view: ring),
                                  makeItem(Self.weeklyIdentifier, view: weeklyLabel),
                                  makeItem(Self.sessionIdentifier, view: sessionLabel),
                                  makeItem(Self.refreshIdentifier, view: refreshButton)]
        touchBar.defaultItemIdentifiers = [Self.ringIdentifier, Self.weeklyIdentifier, .fixedSpaceLarge,
                                           Self.sessionIdentifier, .flexibleSpace, Self.refreshIdentifier]
    }

    func claudeUsageDidChange(_ state: ClaudeUsageState) {
        let now = Date()
        let weekly = state.usage?.weekly
        let session = state.usage?.session
        let weeklyRemaining = weekly?.remainingPercent(at: now)
        let sessionRemaining = session?.remainingPercent(at: now)
        ring.weeklyRemaining = weeklyRemaining
        ring.sessionRemaining = sessionRemaining

        if let weekly, let weeklyRemaining {
            let color = RemainingLevel(remainingPercent: weeklyRemaining).color
            badge.show(Self.percent(weeklyRemaining), color: color)
            let text = NSMutableAttributedString(attributedString: Self.text(
                "Semana \(Self.percent(weeklyRemaining))", size: 15, weight: .semibold, color: color))
            text.append(Self.text("  ↻ \(DurationText.until(weekly.resetsAt, now: now))", size: 13, weight: .regular, color: .labelColor))
            weeklyLabel.attributedStringValue = text
        } else {
            badge.show("!", color: .systemRed)
            weeklyLabel.attributedStringValue = Self.text(state.errorMessage ?? "No data", size: 13,
                                                          weight: .regular, color: .secondaryLabelColor)
        }

        if let session, let sessionRemaining {
            var line = "Session \(Self.percent(sessionRemaining))"
            if let reset = session.resetsAt, reset > now { line += "  ↻ \(DurationText.until(reset, now: now))" }
            sessionLabel.attributedStringValue = Self.text(line, size: 13, weight: .regular,
                                                           color: RemainingLevel(remainingPercent: sessionRemaining).color)
        } else {
            sessionLabel.stringValue = ""
        }
    }

    private func open() {
        delegate?.claudeUsageDidRequestOpen(self)
    }

    @objc private func refresh() {
        onRefresh()
    }

    private func makeItem(_ identifier: NSTouchBarItem.Identifier, view: NSView) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = view
        return item
    }

    private static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private static func text(_ string: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
        ])
    }
}
