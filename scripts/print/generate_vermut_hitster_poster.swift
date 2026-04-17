import AppKit
import CoreGraphics
import Foundation

struct Spec {
    static let instagramSize = CGSize(width: 1024, height: 1776)
    static let a4Size = CGSize(width: 2480, height: 3508)
    static let instagramFooterHeight: CGFloat = 240
    static let footerSampleHeight: CGFloat = 56
}

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outDir = cwd.appendingPathComponent("assets/print", isDirectory: true)
let args = CommandLine.arguments
let baseImageURL = args.count > 1 ? URL(fileURLWithPath: args[1]) : cwd.appendingPathComponent("assets/img/vermut-hitster-base-reference.jpeg")
let outputPrefix = args.count > 2 ? args[2] : "vermut-hitster-bellport"
let cbmeLogoURL = cwd.appendingPathComponent("assets/img/LOGO TRANSPARENTE.png")
let vermutReferenceURL = cwd.appendingPathComponent("assets/img/vermut-a-palamos-reference.jpeg")
let bellportLogoURL = cwd.appendingPathComponent("assets/img/bellport.jpeg")
try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

guard let baseImage = NSImage(contentsOf: baseImageURL) else {
    fputs("No s'ha pogut carregar la imatge base a \(baseImageURL.path)\n", stderr)
    exit(1)
}

guard let cbmeLogo = NSImage(contentsOf: cbmeLogoURL) else {
    fputs("No s'ha pogut carregar el logo de CBME a \(cbmeLogoURL.path)\n", stderr)
    exit(1)
}

guard let vermutReference = NSImage(contentsOf: vermutReferenceURL) else {
    fputs("No s'ha pogut carregar la imatge de referència a \(vermutReferenceURL.path)\n", stderr)
    exit(1)
}

guard let bellportLogo = NSImage(contentsOf: bellportLogoURL) else {
    fputs("No s'ha pogut carregar el logo de Bellport a \(bellportLogoURL.path)\n", stderr)
    exit(1)
}

func aspectFillRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
    let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
    let width = imageSize.width * scale
    let height = imageSize.height * scale
    return CGRect(
        x: bounds.midX - width / 2,
        y: bounds.midY - height / 2,
        width: width,
        height: height
    )
}

func aspectFitRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
    let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
    let width = imageSize.width * scale
    let height = imageSize.height * scale
    return CGRect(
        x: bounds.midX - width / 2,
        y: bounds.midY - height / 2,
        width: width,
        height: height
    )
}

func cgImage(from image: NSImage) -> CGImage? {
    image.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

func cropImage(_ image: NSImage, rect: CGRect) -> NSImage? {
    guard let cgImage = cgImage(from: image),
          let cropped = cgImage.cropping(to: rect) else {
        return nil
    }
    return NSImage(cgImage: cropped, size: rect.size)
}

func renderPNG(size: CGSize, draw: (CGRect) -> Void) throws -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: size.width, height: size.height)
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    draw(CGRect(origin: .zero, size: size))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "poster", code: 1)
    }
    return data
}

func drawRepeatedFooterStrip(in rect: CGRect, tile: NSImage) {
    var y = rect.minY
    while y < rect.maxY {
        let height = min(tile.size.height, rect.maxY - y)
        let dest = CGRect(x: rect.minX, y: y, width: rect.width, height: height)
        let src = CGRect(x: 0, y: 0, width: tile.size.width, height: height)
        tile.draw(in: dest, from: src, operation: .sourceOver, fraction: 1.0)
        y += height
    }
}

func drawRoundedStickerBackground(in rect: CGRect) {
    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24).fill()
}

func drawFooterIcons(in footerRect: CGRect, canvasWidth: CGFloat, centerYOffset: CGFloat, blockXOffset: CGFloat) {
    let widthScale = canvasWidth / Spec.instagramSize.width
    let heightScale = footerRect.height / Spec.instagramFooterHeight

    let footerMidY = footerRect.midY + centerYOffset * heightScale
    let xOffset = blockXOffset * widthScale

    let cbmeBounds = CGRect(
        x: footerRect.minX + 100.0 * widthScale + xOffset,
        y: footerMidY - 289.0 * heightScale / 2.0,
        width: 305.0 * widthScale,
        height: 289.0 * heightScale
    )
    let vermutBounds = CGRect(
        x: footerRect.minX + 435.0 * widthScale + xOffset,
        y: footerMidY - 118.0 * heightScale / 2.0,
        width: 220.0 * widthScale,
        height: 118.0 * heightScale
    )
    let bellportBounds = CGRect(
        x: footerRect.minX + 755.0 * widthScale + xOffset,
        y: footerMidY - 70.0 * heightScale / 2.0,
        width: 205.0 * widthScale,
        height: 70.0 * heightScale
    )

    let cbmeRect = aspectFitRect(imageSize: cbmeLogo.size, in: cbmeBounds)
    cbmeLogo.draw(in: cbmeRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    let vermutRect = aspectFitRect(imageSize: vermutReference.size, in: vermutBounds)
    vermutReference.draw(in: vermutRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    let bellportBacking = CGRect(
        x: bellportBounds.minX - 18.0 * widthScale,
        y: bellportBounds.minY - 14.0 * heightScale,
        width: bellportBounds.width + 36.0 * widthScale,
        height: bellportBounds.height + 28.0 * heightScale
    )
    drawRoundedStickerBackground(in: bellportBacking)
    let bellportRect = aspectFitRect(imageSize: bellportLogo.size, in: bellportBounds)
    bellportLogo.draw(in: bellportRect, from: .zero, operation: .sourceOver, fraction: 1.0)
}

func drawPoster(in canvas: CGRect, footerHeight: CGFloat, footerCenterYOffset: CGFloat, footerBlockXOffset: CGFloat) {
    let artworkRect = CGRect(x: 0, y: footerHeight, width: canvas.width, height: canvas.height - footerHeight)
    baseImage.draw(in: artworkRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    let footerStripRect = CGRect(
        x: 0,
        y: baseImage.size.height - Spec.footerSampleHeight,
        width: baseImage.size.width,
        height: Spec.footerSampleHeight
    )

    if let footerTile = cropImage(baseImage, rect: footerStripRect) {
        let footerRect = CGRect(x: 0, y: 0, width: canvas.width, height: footerHeight)
        drawRepeatedFooterStrip(in: footerRect, tile: footerTile)
        drawFooterIcons(
            in: footerRect,
            canvasWidth: canvas.width,
            centerYOffset: footerCenterYOffset,
            blockXOffset: footerBlockXOffset
        )
    }
}

let instagramData = try renderPNG(size: Spec.instagramSize) { canvas in
    drawPoster(in: canvas, footerHeight: Spec.instagramFooterHeight, footerCenterYOffset: 34, footerBlockXOffset: -35)
}

let instagramURL = outDir.appendingPathComponent("\(outputPrefix)-instagram.png")
let instagramPreviewURL = outDir.appendingPathComponent("\(outputPrefix)-instagram-preview.png")
try instagramData.write(to: instagramURL)
try? fm.removeItem(at: instagramPreviewURL)
try fm.copyItem(at: instagramURL, to: instagramPreviewURL)

let dina4Data = try renderPNG(size: Spec.a4Size) { canvas in
    let footerHeight = round(canvas.height * 0.155)
    drawPoster(in: canvas, footerHeight: footerHeight, footerCenterYOffset: 42, footerBlockXOffset: -45)
}

let dina4URL = outDir.appendingPathComponent("\(outputPrefix)-dina4.png")
let dina4PreviewURL = outDir.appendingPathComponent("\(outputPrefix)-dina4-preview.png")
try dina4Data.write(to: dina4URL)
try? fm.removeItem(at: dina4PreviewURL)
try fm.copyItem(at: dina4URL, to: dina4PreviewURL)

print("Generado:")
print(instagramURL.path)
print(dina4URL.path)
