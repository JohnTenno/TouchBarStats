import AppKit

/// View that shows an image, GIF or video at a fixed size, painting each frame into its layer.
/// It only reloads when the file, the fit or the size changes, so `display` can be called on every settings change.
final class MediaView: NSView {
    /// The Touch Bar and Retina windows draw at 2×; images are pre-rendered at that resolution.
    private static let pixelScale: CGFloat = 2
    /// Waits for the width slider to settle before re-rendering the frames.
    private static let resizeDelay: TimeInterval = 0.3

    private var widthConstraint: NSLayoutConstraint!
    private let height: CGFloat
    private var source: MediaSource?
    private var loaded: (url: URL?, fit: MediaFit, width: CGFloat)?
    private var pendingReload: DispatchWorkItem?

    init(size: NSSize, cornerRadius: CGFloat) {
        height = size.height
        super.init(frame: NSRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: size.width)
        NSLayoutConstraint.activate([widthConstraint, heightAnchor.constraint(equalToConstant: size.height)])
    }

    required init?(coder: NSCoder) {
        fatalError("MediaView is not used from Interface Builder")
    }

    deinit {
        pendingReload?.cancel()
        source?.stop()
    }

    var width: CGFloat {
        get { widthConstraint.constant }
        set { widthConstraint.constant = newValue }
    }

    func display(_ url: URL?, fit: MediaFit) {
        layer?.contentsGravity = fit == .fill ? .resizeAspectFill : .resizeAspect
        guard let loaded else { return reload(url, fit: fit) }
        guard loaded.url != url || loaded.fit != fit || loaded.width != width else { return }
        pendingReload?.cancel()
        // Only a width change is debounced; meanwhile the layer stretches the current frame.
        guard loaded.url == url, loaded.fit == fit else { return reload(url, fit: fit) }
        let work = DispatchWorkItem { [weak self] in self?.reload(url, fit: fit) }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.resizeDelay, execute: work)
    }

    private func reload(_ url: URL?, fit: MediaFit) {
        pendingReload = nil
        let urlChanged = loaded?.url != url
        loaded = (url, fit, width)
        source?.stop()
        if urlChanged { layer?.contents = nil }
        let targetSize = CGSize(width: width * Self.pixelScale, height: height * Self.pixelScale)
        source = url.flatMap { MediaSourceFactory.make(for: $0, targetSize: targetSize, fit: fit) }
        source?.start { [weak self] image in self?.layer?.contents = image }
    }
}
