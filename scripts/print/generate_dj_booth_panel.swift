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
let lightLogoURL = cwd.appendingPathComponent("assets/img/logo-transparente.png")
let darkLogoURL = cwd.appendingPathComponent("assets/img/logo-hero-white-text.png")
try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

guard let lightLogo = NSImage(contentsOf: lightLogoURL),
      let darkLogo = NSImage(contentsOf: darkLogoURL) else {
    fputs("No se pudo cargar alguno de los logos\n", stderr)
    exit(1)
}

let web = "www.costabravamusicevents.com"
let instagram = "@costabrava_music_events"

struct PanelTheme {
    let logo: NSImage
    let textColor: NSColor
    let backgroundColor: NSColor?
    let webFontSize: CGFloat
    let instagramFontSize: CGFloat
    let webYOffset: CGFloat
    let instagramYOffset: CGFloat
}

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

func drawPanel(theme: PanelTheme) {
    let canvas = CGRect(origin: .zero, size: spec.sizePt)

    (theme.backgroundColor ?? NSColor.clear).setFill()
    canvas.fill()

    let logoWidth = canvas.width * 1.42
    let logoRect = CGRect(
        x: canvas.midX - logoWidth / 2,
        y: canvas.midY - logoWidth / 2 + 126,
        width: logoWidth,
        height: logoWidth
    )
    theme.logo.draw(in: logoRect)

    let webRect = CGRect(
        x: canvas.width * 0.015,
        y: canvas.height * theme.webYOffset,
        width: canvas.width * 0.97,
        height: 72
    )
    centeredText(web, in: webRect, attrs: [
        .font: font("Avenir Next Heavy", theme.webFontSize),
        .foregroundColor: theme.textColor
    ])

    let instagramRect = CGRect(
        x: canvas.width * 0.015,
        y: canvas.height * theme.instagramYOffset,
        width: canvas.width * 0.97,
        height: 58
    )
    centeredText(instagram, in: instagramRect, attrs: [
        .font: font("Avenir Next Demi Bold", theme.instagramFontSize),
        .foregroundColor: theme.textColor
    ])
}

func renderPNG(to url: URL, theme: PanelTheme) throws {
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
    drawPanel(theme: theme)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "panel", code: 3)
    }
    try data.write(to: url)
}

func renderPreview(to url: URL, theme: PanelTheme) throws {
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
    drawPanel(theme: theme)
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
let blackPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-black.png")
let blackPreviewPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-black-preview.png")
let blackAirPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-black-air.png")
let blackAirPreviewPNG = outDir.appendingPathComponent("cbme-dj-booth-panel-500x400mm-black-air-preview.png")

let lightTheme = PanelTheme(
    logo: lightLogo,
    textColor: .black,
    backgroundColor: .white,
    webFontSize: 68,
    instagramFontSize: 54,
    webYOffset: 0.055,
    instagramYOffset: 0.012
)
let darkTheme = PanelTheme(
    logo: darkLogo,
    textColor: .white,
    backgroundColor: .black,
    webFontSize: 68,
    instagramFontSize: 54,
    webYOffset: 0.055,
    instagramYOffset: 0.012
)
let darkAirTheme = PanelTheme(
    logo: darkLogo,
    textColor: .white,
    backgroundColor: .black,
    webFontSize: 62,
    instagramFontSize: 50,
    webYOffset: 0.07,
    instagramYOffset: 0.022
)
let transparentTheme = PanelTheme(
    logo: lightLogo,
    textColor: .black,
    backgroundColor: nil,
    webFontSize: 68,
    instagramFontSize: 54,
    webYOffset: 0.055,
    instagramYOffset: 0.012
)

try renderPNG(to: finalPNG, theme: lightTheme)
try renderPreview(to: previewPNG, theme: lightTheme)
try renderPNG(to: transparentPNG, theme: transparentTheme)
try renderPreview(to: transparentPreviewPNG, theme: transparentTheme)
try renderPNG(to: blackPNG, theme: darkTheme)
try renderPreview(to: blackPreviewPNG, theme: darkTheme)
try renderPNG(to: blackAirPNG, theme: darkAirTheme)
try renderPreview(to: blackAirPreviewPNG, theme: darkAirTheme)

print(finalPNG.path)
print(previewPNG.path)
print(transparentPNG.path)
print(transparentPreviewPNG.path)
print(blackPNG.path)
print(blackPreviewPNG.path)
print(blackAirPNG.path)
print(blackAirPreviewPNG.path)
