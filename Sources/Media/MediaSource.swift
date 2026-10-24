import CoreGraphics

/// Strategy: delivers the frames of a still image (one), a GIF or a video (looping).
protocol MediaSource: AnyObject {
    func start(onFrame: @escaping (CGImage) -> Void)
    func stop()
}
