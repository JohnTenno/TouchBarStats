import AppKit

/// Mediator: installs the Control Strip button, shows the detail bar when tapped
/// and opens the fan and Claude usage bars.
final class TouchBarCoordinator: FanControlItemDelegate, ClaudeUsageItemDelegate {
    private let bridge: SystemTouchBarBridge
    private let strip: ControlStripItem
    private let detail: DetailTouchBar

    init(bridge: SystemTouchBarBridge, strip: ControlStripItem, detail: DetailTouchBar,
         fanControl: FanControlItem, claudeUsage: ClaudeUsageItem) {
        self.bridge = bridge
        self.strip = strip
        self.detail = detail
        fanControl.delegate = self
        claudeUsage.delegate = self
        strip.onTap = { [weak self] in self?.showDetail() }
    }

    func install() {
        bridge.addToControlStrip(strip.touchBarItem)
    }

    func fanControlDidRequestOpen(_ item: FanControlItem) {
        bridge.present(item.touchBar, from: strip.touchBarItem)
    }

    func claudeUsageDidRequestOpen(_ item: ClaudeUsageItem) {
        bridge.present(item.touchBar, from: strip.touchBarItem)
    }

    private func showDetail() {
        bridge.present(detail.touchBar, from: strip.touchBarItem)
    }
}
