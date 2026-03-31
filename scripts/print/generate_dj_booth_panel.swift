import AppKit
import CoreGraphics
import Foundation

struct PanelSpec {
    let widthMM: CGFloat
    let heightMM: CGFloat
    let dpi: CGFloat

    var pxWidth: Int { Int((widthMM / 25.4 * dpi).rounded()) }
    var pxHeight: Int { Int((heightMM / 25.4 * dpi).rounded()) }
    var sizePt: CGSize {
        CGSize(width: widthMM * 72.0 / 25.4, height: heightMM * 72.0 / 25.4)
    }
}

let spec = PanelSpec(widthMM: 500, heightMM: 400, dpi: 300)

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outDir = cwd.appendingPathComponent("assets/print", isDirectory: true)
let logoURL = cwd.appendingPathComponent("assets/img/logo-transparente.png")
try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

guard let logo = NSImage(contentsOf: logoURL) else {
    fputs("No se pudo cargar el logo\n", stderr)
    exit(1)
}

let web = "www.costabravamusicevents.com"
let instagram = "@costabrava_music_events"

func font(_ name: String, _ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func centeredText(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
    let attr = NSAttributedString(string: text, attributes: attrs)
    let size = attr.size()
    let drawRect = CGRect(
        x: rect.midX - size.width / 2,
        y: rect.midY - size.height / 2,
        width: size.width,
        height: size.height
    )
    attr.draw(in: drawRect)
}

func drawPanel(backgroundColor: NSColor?) {
    let canvas = CGRect(origin: .zero, size: spec.sizePt)

    (backgroundColor ?? NSColor.clear).setFill()
    canvas.fill()

    let logoWidth = canvas.width * 1.42
    let logoRect = CGRect(
        x: canvas.midX - logoWidth / 2,
        y: canvas.midY - logoWidth / 2 + 126,
        width: logoWidth,
        height: logoWidth
    )
    logo.draw(in: logoRect)

    let webRect = CGRect(
        x: canvas.width * 0.015,
        y: canvas.height * 0.055,
        width: canvas.width * 0.97,
        height: 72
    )
    centeredText(web, in: webRect, attrs: [
        .font: font("Avenir Next Heavy", 68),
        .foregroundColor: NSColor.black
    ])

    let instagramRect = CGRect(
        x: canvas.width * 0.015,
        y: canvas.height * 0.012,
        width: canvas.width * 0.97,
        height: 58
    )
    centeredText(instagram, in: instagramRect, attrs: [
        .font: font("Avenir Next Demi Bold", 54),
        .foregroundColor: NSColor.black
    ])
}

func renderPNG(to url: URL, backgroundColor: NSColor?) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: spec.pxWidth,
        pixelsHigh: spec.pxHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "panel", code: 1)
    }

    rep.size = NSSize(width: spec.sizePt.width, height: spec.sizePt.height)

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        throw NSError(domain: "panel", code: 2)
    }

    ctx.interpolationQuality = .high

    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    drawPanel(backgroundColor: backgroundColor)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "panel", code: 3)
    }
    try data.write(to: url)
}

func renderPreview(to url: URL, backgroundColor: NSColor?) throws {
    let previewWidth = 1800
    let previewHeight = Int((Double(previewWidth) * Double(spec.pxHeight) / Double(spec.pxWidth)).rounded())

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: previewWidth,
        pixelsHigh: previewHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "panel", code: 4)
    }

    rep.size = NSSize(width: spec.sizePt.width, height: spec.sizePt.height)

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        throw NSError(domain: "panel", code: 5)
    }

    ctx.interpolationQuality = .high

    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    drawPanel(backgroundColor: backgroundColor)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "panel", code: 6)
    }
    try data.write(to: url)
}

let finalPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm.png")
let previewPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-preview.png")
let transparentPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-transparent.png")
let transparentPreviewPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-transparent-preview.png")

try renderPNG(to: finalPNG, backgroundColor: .white)
try renderPreview(to: previewPNG, backgroundColor: .white)
try renderPNG(to: transparentPNG, backgroundColor: nil)
try renderPreview(to: transparentPreviewPNG, backgroundColor: nil)

print(finalPNG.path)
print(previewPNG.path)
print(transparentPNG.path)
print(transparentPreviewPNG.path)
