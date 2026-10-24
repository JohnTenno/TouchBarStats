/// Everything the user can adjust without recompiling. Saved as JSON (see SettingsStore).
struct AppSettings: Codable, Equatable {
    static let mediaWidthRange: ClosedRange<Double> = 30...600
    static let refreshIntervals: [Double] = [1, 2, 3, 5, 10]

    /// Detail bar items in display order.
    var items: [BarItemEntry]
    /// Control Strip icon; with no file the app icon is used.
    var stripIcon: MediaChoice
    /// GIF or video of the "Animation" item.
    var media: MediaChoice
    var mediaWidth: Double
    /// How many seconds between reads of CPU, GPU, RAM, temperatures and fan.
    var refreshInterval: Double
    var showsMenuBarIcon: Bool

    static let defaults = AppSettings(
        items: BarItem.allCases.map { BarItemEntry(item: $0, isVisible: $0.isVisibleByDefault) },
        stripIcon: MediaChoice(fit: .fill),
        media: MediaChoice(fit: .fill),
        mediaWidth: 120,
        refreshInterval: 2,
        showsMenuBarIcon: true)

    init(items: [BarItemEntry], stripIcon: MediaChoice, media: MediaChoice, mediaWidth: Double,
         refreshInterval: Double, showsMenuBarIcon: Bool) {
        self.items = items
        self.stripIcon = stripIcon
        self.media = media
        self.mediaWidth = mediaWidth
        self.refreshInterval = refreshInterval
        self.showsMenuBarIcon = showsMenuBarIcon
    }

    /// Tolerates old or partial JSON: missing values take the default and unknown items are ignored.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults
        let rawItems = try container.decodeIfPresent([RawEntry].self, forKey: .items) ?? []
        items = rawItems.compactMap { raw in BarItem(rawValue: raw.item).map { BarItemEntry(item: $0, isVisible: raw.isVisible) } }
        stripIcon = try container.decodeIfPresent(MediaChoice.self, forKey: .stripIcon) ?? defaults.stripIcon
        media = try container.decodeIfPresent(MediaChoice.self, forKey: .media) ?? defaults.media
        mediaWidth = try container.decodeIfPresent(Double.self, forKey: .mediaWidth) ?? defaults.mediaWidth
        refreshInterval = try container.decodeIfPresent(Double.self, forKey: .refreshInterval) ?? defaults.refreshInterval
        showsMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showsMenuBarIcon) ?? defaults.showsMenuBarIcon
        self = normalized()
    }

    /// The items shown in the bar, in order. The animation only counts once it has a file.
    var visibleItems: [BarItem] {
        items.filter { $0.isVisible && ($0.item != .media || media.path != nil) }.map(\.item)
    }

    func isVisible(_ item: BarItem) -> Bool {
        items.first { $0.item == item }?.isVisible ?? false
    }

    mutating func setVisible(_ item: BarItem, _ visible: Bool) {
        guard let index = items.firstIndex(where: { $0.item == item }) else { return }
        items[index].isVisible = visible
    }

    /// Moves an item `offset` places (negative = toward the left of the bar).
    mutating func move(_ item: BarItem, by offset: Int) {
        guard let from = items.firstIndex(where: { $0.item == item }) else { return }
        let to = min(max(from + offset, 0), items.count - 1)
        guard to != from else { return }
        items.insert(items.remove(at: from), at: to)
    }

    /// No duplicates, every known item present and values within range.
    func normalized() -> AppSettings {
        var copy = self
        var seen = Set<BarItem>()
        copy.items = items.filter { seen.insert($0.item).inserted }
        copy.items += BarItem.allCases.filter { !seen.contains($0) }
            .map { BarItemEntry(item: $0, isVisible: $0.isVisibleByDefault) }
        copy.mediaWidth = min(max(mediaWidth, Self.mediaWidthRange.lowerBound), Self.mediaWidthRange.upperBound)
        copy.refreshInterval = min(max(refreshInterval, 1), 60)
        return copy
    }

    private struct RawEntry: Decodable {
        let item: String
        let isVisible: Bool
    }
}
