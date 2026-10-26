//
//  RecolorEngine.swift
//  TaulbeePainting
//
//  On-device instant recoloring for one photo and any number of detected
//  surfaces. Each surface is prepared once from its AI-detected mask; the
//  engine then composites any combination of paint colors — layered in
//  real-job order (trim and doors over walls) — while preserving the photo's
//  lighting, shadows, and texture. Runs on the GPU via Core Image, so trying
//  a new color is immediate and free.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Thrown when a detection mask can't produce believable recolors.
nonisolated enum RecolorError: Error {
    case invalidImage
    case maskUnusable
}

/// GPU recoloring pipeline for one photo + its detected surfaces.
actor RecolorEngine {
    /// Everything needed to repaint one detected surface.
    private struct SurfaceLayer {
        let featheredMask: CIImage
        let shading: CIImage
    }

    private let context: CIContext
    private let original: CIImage
    private let luma: CIImage
    private let extent: CGRect
    private var layers: [PaintTarget: SurfaceLayer] = [:]

    /// Builds the shared pipeline from an upright photo. Surfaces are added
    /// individually via `addSurface` as their masks are detected.
    init(photo: UIImage) throws {
        guard let photoCG = photo.cgImage else {
            throw RecolorError.invalidImage
        }

        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        context = CIContext(options: [
            .workingColorSpace: srgb,
            .outputColorSpace: srgb
        ])

        let base = CIImage(cgImage: photoCG)
        original = base
        extent = base.extent
        // Luminance-only photo: keeps lighting, shadows, and texture.
        luma = Self.grayscale(of: base)
    }

    /// Prepares a detected surface for instant recoloring. Heavier than a
    /// render (two GPU reductions), so it runs on the actor's executor.
    func addSurface(_ target: PaintTarget, mask: UIImage) throws {
        guard let maskCG = mask.cgImage else { throw RecolorError.invalidImage }

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

        layers[target] = SurfaceLayer(featheredMask: feathered, shading: shading)
    }

    /// Repaints every assigned surface (target → swatch hex) in one pass,
    /// layered by `zOrder` so trim and doors paint over walls. Fast enough to
    /// call on every color tap.
    func render(_ assignments: [PaintTarget: String]) -> UIImage? {
        let ordered = assignments.keys
            .filter { layers[$0] != nil }
            .sorted { $0.zOrder < $1.zOrder }
        guard !ordered.isEmpty else { return nil }

        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        var accumulated = original

        for target in ordered {
            guard let layer = layers[target], let hex = assignments[target] else { continue }

            let rgb = PaintColor.rgb(from: hex)
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
            overlay.backgroundImage = layer.shading
            guard let painted = overlay.outputImage else { continue }

            let composite = CIFilter.blendWithMask()
            composite.inputImage = painted
            composite.backgroundImage = accumulated
            composite.maskImage = layer.featheredMask
            guard let output = composite.outputImage else { continue }
            accumulated = output
        }

        guard let cgImage = context.createCGImage(accumulated, from: extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// True when a surface has a prepared layer.
    func hasSurface(_ target: PaintTarget) -> Bool {
        layers[target] != nil
    }

    /// Drops a prepared surface so it can be detected again.
    func removeSurface(_ target: PaintTarget) {
        layers[target] = nil
    }

    /// A transparent overlay that tints the detected surface and traces its
    /// edge, so the customer can see exactly what will be painted.
    func highlight(_ target: PaintTarget, hex: String = "8B4AC4") -> UIImage? {
        guard let layer = layers[target] else { return nil }

        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let rgb = PaintColor.rgb(from: hex)
        let tint = CIColor(red: CGFloat(rgb.r), green: CGFloat(rgb.g), blue: CGFloat(rgb.b), colorSpace: srgb)
            ?? CIColor(red: CGFloat(rgb.r), green: CGFloat(rgb.g), blue: CGFloat(rgb.b))
        let flat = CIImage(color: tint).cropped(to: extent)
        let clear = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent)

        // Soft fill across the whole surface.
        let fillBlend = CIFilter.blendWithMask()
        fillBlend.inputImage = flat
        fillBlend.backgroundImage = clear
        fillBlend.maskImage = layer.featheredMask
        guard let fillOpaque = fillBlend.outputImage else { return nil }

        let fade = CIFilter.colorMatrix()
        fade.inputImage = fillOpaque
        fade.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.38)
        let fill = fade.outputImage ?? fillOpaque

        // Bright edge: the mask minus a slightly eroded copy of itself.
        let erode = CIFilter.morphologyMinimum()
        erode.inputImage = layer.featheredMask.clampedToExtent()
        erode.radius = Float(max(2.5, min(extent.width, extent.height) / 160))
        let difference = CIFilter.differenceBlendMode()
        difference.inputImage = layer.featheredMask
        difference.backgroundImage = erode.outputImage?.cropped(to: extent) ?? layer.featheredMask
        let edgeMask = difference.outputImage ?? layer.featheredMask

        let edgeBlend = CIFilter.blendWithMask()
        edgeBlend.inputImage = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: extent)
        edgeBlend.backgroundImage = clear
        edgeBlend.maskImage = edgeMask
        let edge = edgeBlend.outputImage ?? clear

        let combined = edge.composited(over: fill)
        guard let cgImage = context.createCGImage(combined, from: extent) else { return nil }
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
