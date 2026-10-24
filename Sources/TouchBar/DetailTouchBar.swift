import AppKit

/// Full Touch Bar: metrics, fan control, Claude usage, animation and gear,
/// in the order and visibility set in Settings. Rebuilt live when they change.
final class DetailTouchBar: NSObject, SnapshotObserver, SettingsObserver {
    let touchBar = NSTouchBar()
    private let formatter: SnapshotFormatter
    private var badges: [Metric: MetricBadgeView] = [:]
    private var items: [BarItem: NSTouchBarItem] = [:]

    init(formatter: SnapshotFormatter, fanControl: NSTouchBarItem, claudeUsage: NSTouchBarItem,
         media: NSTouchBarItem, settingsButton: NSTouchBarItem) {
        self.formatter = formatter
        super.init()
        for item in BarItem.allCases {
            if let metric = item.metric { items[item] = makeItem(for: metric) }
        }
        items[.fanControl] = fanControl
        items[.claude] = claudeUsage
        items[.media] = media
        items[.settings] = settingsButton
        touchBar.templateItems = Set(items.values)
    }

    func monitorDidCapture(_ snapshot: SystemSnapshot) {
        badges.forEach { metric, badge in badge.show(formatter.format(metric, in: snapshot)) }
    }

    func settingsDidChange(_ settings: AppSettings) {
        let identifiers = settings.visibleItems.compactMap { items[$0]?.identifier }
        if touchBar.defaultItemIdentifiers != identifiers {
            touchBar.defaultItemIdentifiers = identifiers
        }
    }

    private func makeItem(for metric: Metric) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .init("com.tenno.TouchBarStats.\(metric)"))
        let badge = MetricBadgeView(showsDetail: true, fontSize: 13)
        badges[metric] = badge
        item.view = badge
        return item
    }
}
