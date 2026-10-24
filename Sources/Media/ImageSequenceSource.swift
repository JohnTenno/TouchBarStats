import CoreGraphics
import Foundation

/// Loops the frames of an image honoring each frame's duration; with a single frame it just shows it.
/// Frames are decoded once in the background, already at display size, so playback costs no CPU.
final class ImageSequenceSource: MediaSource {
    private static let decodeQueue = DispatchQueue(label: "com.tenno.TouchBarStats.image-decode", qos: .utility)

    private let url: URL
    private let targetSize: CGSize
    private let fit: MediaFit
    private var frames: [ImageFrame] = []
    private var timer: Timer?
    private var index = 0
    /// Bumped on every start/stop so a decode that finishes late is ignored.
    private var generation = 0

    init(url: URL, targetSize: CGSize, fit: MediaFit) {
        self.url = url
        self.targetSize = targetSize
        self.fit = fit
    }

    func start(onFrame: @escaping (CGImage) -> Void) {
        stop()
        let generation = generation
        if !frames.isEmpty { return play(onFrame) }
        let url = url, targetSize = targetSize, fit = fit
        Self.decodeQueue.async { [weak self] in
            let frames = ImageFrameDecoder.frames(from: url, targetSize: targetSize, fit: fit)
            DispatchQueue.main.async {
                guard let self, self.generation == generation else { return }
                self.frames = frames
                self.play(onFrame)
            }
        }
    }

    func stop() {
        generation += 1
        timer?.invalidate()
        timer = nil
    }

    private func play(_ onFrame: @escaping (CGImage) -> Void) {
        guard let first = frames.first else { return }
        index = 0
        onFrame(first.image)
        if frames.count > 1 { scheduleNext(onFrame) }
    }

    private func scheduleNext(_ onFrame: @escaping (CGImage) -> Void) {
        let timer = Timer(timeInterval: frames[index].duration, repeats: false) { [weak self] _ in
            guard let self else { return }
            index = (index + 1) % frames.count
            onFrame(frames[index].image)
            scheduleNext(onFrame)
        }
        // .common so it keeps animating while the slider is dragged or a menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
