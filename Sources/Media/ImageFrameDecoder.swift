import CoreGraphics
import Foundation
import ImageIO

/// Reads every frame of an image (PNG, JPG, GIF, APNG, WebP, HEICS) pre-rendered at the size it is shown,
/// cropped to the visible part when filling. Each frame is decoded once at full size and dropped right
/// away, so a 120-frame 500 px GIF shown in a 30 pt Touch Bar item takes ~11 MB instead of ~110 MB.
enum ImageFrameDecoder {
    private static let defaultDuration: TimeInterval = 0.1
    /// Browsers treat delays under 20 ms as 100 ms; mimic that so GIFs don't play too fast.
    private static let minimumDuration: TimeInterval = 0.02

    private static let delayKeys: [(dictionary: CFString, unclamped: CFString, clamped: CFString)] = [
        (kCGImagePropertyGIFDictionary, kCGImagePropertyGIFUnclampedDelayTime, kCGImagePropertyGIFDelayTime),
        (kCGImagePropertyPNGDictionary, kCGImagePropertyAPNGUnclampedDelayTime, kCGImagePropertyAPNGDelayTime),
        (kCGImagePropertyWebPDictionary, kCGImagePropertyWebPUnclampedDelayTime, kCGImagePropertyWebPDelayTime),
        (kCGImagePropertyHEICSDictionary, kCGImagePropertyHEICSUnclampedDelayTime, kCGImagePropertyHEICSDelayTime),
    ]

    /// `targetSize` is in pixels. Safe to call off the main thread.
    static func frames(from url: URL, targetSize: CGSize, fit: MediaFit) -> [ImageFrame] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return [] }
        let decodeOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        return (0..<CGImageSourceGetCount(source)).compactMap { index in
            autoreleasepool {
                guard let image = CGImageSourceCreateImageAtIndex(source, index, decodeOptions),
                      let rendered = render(image, targetSize: targetSize, fit: fit) else { return nil }
                return ImageFrame(image: rendered, duration: duration(of: source, at: index))
            }
        }
    }

    private static func duration(of source: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return defaultDuration
        }
        for keys in delayKeys {
            guard let info = properties[keys.dictionary] as? [CFString: Any] else { continue }
            let delay = (info[keys.unclamped] as? Double) ?? (info[keys.clamped] as? Double) ?? defaultDuration
            return delay < minimumDuration ? defaultDuration : delay
        }
        return defaultDuration
    }

    private static func render(_ image: CGImage, targetSize: CGSize, fit: MediaFit) -> CGImage? {
        let geometry = FrameGeometry(imageSize: CGSize(width: image.width, height: image.height),
                                     targetSize: targetSize, fit: fit)
        guard let context = CGContext(data: nil, width: Int(geometry.outputSize.width),
                                      height: Int(geometry.outputSize.height), bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: geometry.drawRect)
        return context.makeImage()
    }
}
