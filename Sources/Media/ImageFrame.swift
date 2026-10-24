import CoreGraphics
import Foundation

/// One frame of an animated image and how long it stays on screen.
struct ImageFrame {
    let image: CGImage
    let duration: TimeInterval
}
