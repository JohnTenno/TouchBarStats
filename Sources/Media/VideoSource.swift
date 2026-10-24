import AVFoundation
import QuartzCore
import VideoToolbox

/// Looping, muted video. Instead of AVPlayerLayer (which is not drawn on the Touch Bar, because it
/// is composited in another process) it pulls every frame as a CGImage and delivers it like a GIF.
final class VideoSource: MediaSource {
    private static let framesPerSecond = 30.0

    private let player: AVPlayer
    private let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    ])
    private var timer: Timer?
    private var loopObserver: NSObjectProtocol?

    init(url: URL) {
        let item = AVPlayerItem(url: url)
        item.add(output)
        player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.preventsDisplaySleepDuringVideoPlayback = false
    }

    func start(onFrame: @escaping (CGImage) -> Void) {
        stop()
        loopObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem, queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }
        player.play()
        let timer = Timer(timeInterval: 1 / Self.framesPerSecond, repeats: true) { [weak self] _ in
            self?.pullFrame(onFrame)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player.pause()
        if let loopObserver { NotificationCenter.default.removeObserver(loopObserver) }
        loopObserver = nil
    }

    private func pullFrame(_ onFrame: (CGImage) -> Void) {
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard output.hasNewPixelBuffer(forItemTime: time),
              let buffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &image)
        if let image { onFrame(image) }
    }
}
