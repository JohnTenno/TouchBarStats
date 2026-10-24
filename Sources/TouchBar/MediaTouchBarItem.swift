import AppKit

/// "Animation" item: the GIF or video chosen in Settings, at the chosen width, looping next to the metrics.
final class MediaTouchBarItem: NSObject, SettingsObserver {
    private static let height: CGFloat = 30

    let item = NSCustomTouchBarItem(identifier: .init("com.tenno.TouchBarStats.media"))
    private let mediaView = MediaView(size: NSSize(width: AppSettings.defaults.mediaWidth, height: height),
                                      cornerRadius: 6)

    override init() {
        super.init()
        item.view = mediaView
    }

    func settingsDidChange(_ settings: AppSettings) {
        mediaView.width = settings.mediaWidth
        let path = settings.visibleItems.contains(.media) ? settings.media.path : nil
        mediaView.display(path.map { URL(fileURLWithPath: $0) }, fit: settings.media.fit)
    }
}
