import AppKit

/// Icon + text of a metric, colored by its alert level.
final class MetricBadgeView: NSStackView {
    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "--")
    private let showsDetail: Bool

    init(showsDetail: Bool, fontSize: CGFloat) {
        self.showsDetail = showsDetail
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 3
        label.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        icon.symbolConfiguration = .init(pointSize: fontSize, weight: .medium)
        addArrangedSubview(icon)
        addArrangedSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("MetricBadgeView is not used from Interface Builder")
    }

    func show(_ metric: FormattedMetric) {
        if icon.image == nil {
            icon.image = NSImage(systemSymbolName: metric.symbolName, accessibilityDescription: metric.title)
        }
        let color = metric.level.color
        let text = showsDetail ? metric.detailValue : metric.shortValue
        if icon.contentTintColor != color { icon.contentTintColor = color }
        if label.stringValue != text { label.stringValue = text }
        if label.textColor != color { label.textColor = color }
    }
}
