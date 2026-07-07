//
//  RecolorEngine.swift
//  TaulbeePainting
//
//  On-device instant recoloring. Prepared once per photo + detected surface
//  mask, it composites any paint color onto the surface while preserving the
//  photo's real lighting, shadows, and texture. Runs on the GPU via Core
//  Image, so trying a new color is immediate and free.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Thrown when a detection mask can't produce believable recolors.
nonisolated enum RecolorError: Error {
    case invalidImage
    case maskUnusable
}

/// GPU recoloring pipeline for one photo + one detected surface.
actor RecolorEngine {
    private let context: CIContext
    private let original: CIImage
    private let featheredMask: CIImage
    private let shading: CIImage
    private let extent: CGRect

    /// Fraction of the photo covered by the detected surface (0...1).
    let coverage: Double

    /// Builds the pipeline from an upright photo and the AI-detected mask.
    /// Heavier than a render (two GPU reductions), so create it off the main
    /// thread via `Task.detached`.
    init(photo: UIImage, mask: UIImage) throws {
        guard let photoCG = photo.cgImage, let maskCG = mask.cgImage else {
            throw RecolorError.invalidImage
        }

        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let context = CIContext(options: [
            .workingColorSpace: srgb,
            .outputColorSpace: srgb
        ])

        let base = CIImage(cgImage: photoCG)
        let extent = base.extent

        // Stretch the AI mask to cover the photo exactly.
        let rawMask = CIImage(cgImage: maskCG)
        guard rawMask.extent.width > 0, rawMask.extent.height > 0 else {
            throw RecolorError.invalidImage
        }
        let scaled = rawMask.transformed(by: CGAffineTransform(
            scaleX: extent.width / rawMask.extent.width,
            y: extent.height / rawMask.extent.height
        ))

        // Force a clean two-tone mask regardless of JPEG noise.
        let threshold = CIFilter.colorThreshold()
        threshold.inputImage = scaled
        threshold.threshold = 0.5
        guard let binaryMask = threshold.outputImage?.cropped(to: extent) else {
            throw RecolorError.maskUnusable
        }

        // Reject masks that found (almost) nothing.
        let coverage = Self.averageValue(of: binaryMask, extent: extent, context: context)
        guard coverage > 0.02 else { throw RecolorError.maskUnusable }

        // Luminance-only photo: keeps lighting, shadows, and texture.
        let luma = Self.grayscale(of: base)

        // Average brightness of the surface itself, so the chosen paint reads
        // true at the room's typical lighting level.
        let masked = CIFilter.multiplyCompositing()
        masked.inputImage = luma
        masked.backgroundImage = binaryMask
        let maskedAverage = Self.averageValue(
            of: masked.outputImage ?? luma,
            extent: extent,
            context: context
        )
        let surfaceLuma = max(0.06, maskedAverage / max(0.02, coverage))
        let gain = min(2.8, max(0.65, 0.5 / surfaceLuma))

        let normalize = CIFilter.colorMatrix()
        normalize.inputImage = luma
        normalize.rVector = CIVector(x: gain, y: 0, z: 0, w: 0)
        normalize.gVector = CIVector(x: 0, y: gain, z: 0, w: 0)
        normalize.bVector = CIVector(x: 0, y: 0, z: gain, w: 0)
        normalize.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let shading = normalize.outputImage else { throw RecolorError.maskUnusable }

        // Soft edge so the recolor blends naturally at boundaries.
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = binaryMask.clampedToExtent()
        blur.radius = Float(max(1.2, min(extent.width, extent.height) / 420))
        let feathered = blur.outputImage?.cropped(to: extent) ?? binaryMask

        self.context = context
        self.original = base
        self.featheredMask = feathered
        self.shading = shading
        self.extent = extent
        self.coverage = coverage
    }

    /// Repaints the detected surface with the given swatch hex. Fast enough
    /// to call on every color tap.
    func render(hex: String) -> UIImage? {
        let rgb = PaintColor.rgb(from: hex)
        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let ciColor = CIColor(
            red: CGFloat(rgb.r),
            green: CGFloat(rgb.g),
            blue: CGFloat(rgb.b),
            colorSpace: srgb
        ) ?? CIColor(red: CGFloat(rgb.r), green: CGFloat(rgb.g), blue: CGFloat(rgb.b))
        let flat = CIImage(color: ciColor).cropped(to: extent)

        // Overlay keeps highlights and shadows while adopting the paint color.
        let overlay = CIFilter.overlayBlendMode()
        overlay.inputImage = flat
        overlay.backgroundImage = shading
        guard let painted = overlay.outputImage else { return nil }

        let composite = CIFilter.blendWithMask()
        composite.inputImage = painted
        composite.backgroundImage = original
        composite.maskImage = featheredMask
        guard let output = composite.outputImage,
              let cgImage = context.createCGImage(output, from: extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Static helpers

    private nonisolated static func grayscale(of image: CIImage) -> CIImage {
        let filter = CIFilter.colorMatrix()
        filter.inputImage = image
        filter.rVector = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
        filter.gVector = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
        filter.bVector = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
        filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        return filter.outputImage ?? image
    }

    /// Mean red-channel value of `image` over `extent` (0...1).
    private nonisolated static func averageValue(
        of image: CIImage,
        extent: CGRect,
        context: CIContext
    ) -> Double {
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = extent
        guard let output = filter.outputImage else { return 0 }
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )
        return Double(pixel[0]) / 255.0
    }
}
