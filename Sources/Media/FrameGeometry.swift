import CoreGraphics

/// Where an image lands when it is pre-rendered for a view `targetSize` pixels big:
/// `.fill` keeps only the part that will be visible, `.fit` keeps the whole image.
/// Never upscales; the layer stretches small images, so the bitmap stays as small as possible.
struct FrameGeometry {
    /// Size of the bitmap to render into.
    let outputSize: CGSize
    /// Where to draw the whole source image inside that bitmap (it may stick out, which crops it).
    let drawRect: CGRect

    init(imageSize: CGSize, targetSize: CGSize, fit: MediaFit) {
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let viewScale = fit == .fill ? max(widthRatio, heightRatio) : min(widthRatio, heightRatio)
        let scale = min(viewScale, 1)

        // Part of the source (in source pixels) that ends up on screen.
        let visible = fit == .fill
            ? CGSize(width: min(imageSize.width, targetSize.width / viewScale),
                     height: min(imageSize.height, targetSize.height / viewScale))
            : imageSize
        outputSize = CGSize(width: max(1, (visible.width * scale).rounded()),
                            height: max(1, (visible.height * scale).rounded()))
        let drawn = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        drawRect = CGRect(x: (outputSize.width - drawn.width) / 2, y: (outputSize.height - drawn.height) / 2,
                          width: drawn.width, height: drawn.height)
    }
}
