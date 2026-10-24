import AppKit

/// Fan button that opens its own bar, like the volume one: Auto/Manual, slider and rpm.
/// Does not use NSPopoverTouchBarItem because it does not expand inside a system modal bar.
/// Moving the slider switches to manual; in automatic the slider follows the real fan speed.
final class FanControlItem: NSObject, SnapshotObserver {
    private static let buttonIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.fanControl")
    private static let modeIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.fanMode")
    private static let sliderIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.fanSlider")
    private static let speedIdentifier = NSTouchBarItem.Identifier("com.tenno.TouchBarStats.fanSpeed")
    private static let automaticSegment = 0
    private static let manualSegment = 1
    private static let sliderStep = 0.01
    private static let fontSize: CGFloat = 13

    weak var delegate: FanControlItemDelegate?
    let buttonItem = NSCustomTouchBarItem(identifier: FanControlItem.buttonIdentifier)
    let touchBar = NSTouchBar()
    private let client: FanControlClient
    private let formatter: SnapshotFormatter
    private let openButton = NSButton(title: "Auto", image: FanControlItem.symbol("fan"), target: nil, action: nil)
    private let modeControl = NSSegmentedControl(labels: ["Auto", "Manual"], trackingMode: .selectOne,
                                                 target: nil, action: nil)
    private let slider = FanSpeedSliderView()
    private let speedBadge = MetricBadgeView(showsDetail: true, fontSize: FanControlItem.fontSize)
    private var lastCommand: FanCommand = .automatic
    private var helperMissing = false

    init(client: FanControlClient, formatter: SnapshotFormatter) {
        self.client = client
        self.formatter = formatter
        super.init()
        openButton.target = self
        openButton.action = #selector(open)
        openButton.imagePosition = .imageLeading
        openButton.font = .monospacedDigitSystemFont(ofSize: Self.fontSize, weight: .medium)
        buttonItem.view = openButton
        modeControl.target = self
        modeControl.action = #selector(modeChanged)
        slider.onChange = { [weak self] _ in self?.sliderMoved() }

        touchBar.templateItems = [makeItem(Self.modeIdentifier, view: modeControl),
                                  makeItem(Self.sliderIdentifier, view: slider),
                                  makeItem(Self.speedIdentifier, view: speedBadge)]
        touchBar.defaultItemIdentifiers = [Self.modeIdentifier, Self.sliderIdentifier, Self.speedIdentifier]
        showMode()
    }

    func monitorDidCapture(_ snapshot: SystemSnapshot) {
        if case .automatic = lastCommand, let reading = snapshot.fan {
            slider.setFraction(reading.rangeFraction)
        }
        guard !helperMissing else { return }
        speedBadge.show(formatter.format(.fan, in: snapshot))
    }

    @objc private func open() {
        delegate?.fanControlDidRequestOpen(self)
    }

    @objc private func modeChanged() {
        apply(modeControl.selectedSegment == Self.manualSegment ? .manual(fraction: sliderFraction) : .automatic)
    }

    private func sliderMoved() {
        apply(.manual(fraction: sliderFraction))
    }

    private var sliderFraction: Double {
        (slider.fraction / Self.sliderStep).rounded() * Self.sliderStep
    }

    private func apply(_ command: FanCommand) {
        guard command != lastCommand else { return }
        helperMissing = !client.send(command)
        if !helperMissing {
            lastCommand = command
        } else {
            lastCommand = .automatic
            speedBadge.show(FormattedMetric(title: "Fan", symbolName: "fan", shortValue: "!",
                                            detailValue: "Install the helper", level: .critical))
        }
        showMode()
    }

    private func showMode() {
        switch lastCommand {
        case .automatic:
            openButton.title = "Auto"
            modeControl.selectedSegment = Self.automaticSegment
            slider.isActive = false
        case .manual(let fraction):
            openButton.title = "\(Int((fraction * 100).rounded()))%"
            modeControl.selectedSegment = Self.manualSegment
            slider.isActive = true
        }
    }

    private func makeItem(_ identifier: NSTouchBarItem.Identifier, view: NSView) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = view
        return item
    }

    private static func symbol(_ name: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage()
        return image.withSymbolConfiguration(.init(pointSize: fontSize, weight: .medium)) ?? image
    }
}
