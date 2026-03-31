import AppKit
import CoreGraphics
import Foundation

struct Specs {
    static let dpi: CGFloat = 300
    static let mmToPt: CGFloat = 72.0 / 25.4
    static let bleedMM: CGFloat = 3
    static let trimWidthMM: CGFloat = 85
    static let trimHeightMM: CGFloat = 55
    static let pageWidthMM: CGFloat = trimWidthMM + bleedMM * 2
    static let pageHeightMM: CGFloat = trimHeightMM + bleedMM * 2
    static let pageSize = CGSize(width: pageWidthMM * mmToPt, height: pageHeightMM * mmToPt)
    static let trimRect = CGRect(
        x: bleedMM * mmToPt,
        y: bleedMM * mmToPt,
        width: trimWidthMM * mmToPt,
        height: trimHeightMM * mmToPt
    )
    static let safeRect = trimRect.insetBy(dx: 5 * mmToPt, dy: 5 * mmToPt)
}

enum P {
    static let deep = NSColor(calibratedRed: 6 / 255, green: 20 / 255, blue: 40 / 255, alpha: 1)
    static let deep2 = NSColor(calibratedRed: 10 / 255, green: 31 / 255, blue: 56 / 255, alpha: 1)
    static let aqua = NSColor(calibratedRed: 34 / 255, green: 211 / 255, blue: 238 / 255, alpha: 1)
    static let amber = NSColor(calibratedRed: 251 / 255, green: 191 / 255, blue: 36 / 255, alpha: 1)
    static let coral = NSColor(calibratedRed: 246 / 255, green: 121 / 255, blue: 87 / 255, alpha: 1)
    static let offWhite = NSColor(calibratedRed: 247 / 255, green: 245 / 255, blue: 240 / 255, alpha: 1)
    static let mist = NSColor(calibratedRed: 229 / 255, green: 236 / 255, blue: 245 / 255, alpha: 1)
    static let slate = NSColor(calibratedRed: 84 / 255, green: 96 / 255, blue: 119 / 255, alpha: 1)
    static let line = NSColor(calibratedRed: 216 / 255, green: 224 / 255, blue: 235 / 255, alpha: 1)
}

struct Variant {
    let slug: String
    let name: String
}

let variants: [Variant] = [
    .init(slug: "editorial", name: "Editorial"),
    .init(slug: "midnight", name: "Midnight"),
    .init(slug: "split", name: "Split")
]

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outDir = cwd.appendingPathComponent("assets/print", isDirectory: true)
let logoURL = cwd.appendingPathComponent("assets/img/logo-transparente.png")
try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

guard let logo = NSImage(contentsOf: logoURL) else {
    fputs("No se pudo cargar el logo\n", stderr)
    exit(1)
}

let phones = "619 840 602 / 687 962 905"
let email = "info@costabravamusicevents.com"
let web = "www.costabravamusicevents.com"
let tagline = "Música a medida para eventos"

func font(_ name: String, _ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func paragraph(_ alignment: NSTextAlignment = .left, _ spacing: CGFloat = 0) -> NSParagraphStyle {
    let s = NSMutableParagraphStyle()
    s.alignment = alignment
    s.lineSpacing = spacing
    return s
}

func drawText(_ text: String, rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
    NSAttributedString(string: text, attributes: attrs).draw(in: rect)
}

func centeredText(_ text: String, point: CGPoint, attrs: [NSAttributedString.Key: Any]) {
    let attr = NSAttributedString(string: text, attributes: attrs)
    let size = attr.size()
    attr.draw(in: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height))
}

func fill(_ color: NSColor, _ rect: CGRect) {
    color.setFill()
    NSBezierPath(rect: rect).fill()
}

func line(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat = 1) {
    let path = NSBezierPath()
    path.move(to: from)
    path.line(to: to)
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawLogo(in rect: CGRect) {
    logo.draw(in: rect)
}

func drawEditorialFront() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let trim = Specs.trimRect
    fill(P.offWhite, page)

    if let g1 = NSGradient(colors: [P.aqua.withAlphaComponent(0.18), .clear]) {
        g1.draw(fromCenter: CGPoint(x: trim.minX + trim.width * 0.20, y: trim.maxY - 12), radius: 0, toCenter: CGPoint(x: trim.minX + trim.width * 0.20, y: trim.maxY - 12), radius: trim.width * 0.33, options: [])
    }
    if let g2 = NSGradient(colors: [P.amber.withAlphaComponent(0.16), .clear]) {
        g2.draw(fromCenter: CGPoint(x: trim.maxX - trim.width * 0.18, y: trim.minY + 10), radius: 0, toCenter: CGPoint(x: trim.maxX - trim.width * 0.18, y: trim.minY + 10), radius: trim.width * 0.30, options: [])
    }

    drawLogo(in: CGRect(x: trim.midX - 120, y: trim.midY - 46, width: 240, height: 240))
    line(from: CGPoint(x: trim.minX + 30, y: trim.minY + 30), to: CGPoint(x: trim.maxX - 30, y: trim.minY + 30), color: P.deep.withAlphaComponent(0.14))

    let attrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", 9.4),
        .foregroundColor: P.slate,
        .kern: 2
    ]
    centeredText("DJ  LIVE MUSIC  SOUND  LIGHTING", point: CGPoint(x: trim.midX, y: trim.minY + 20), attrs: attrs)
}

func drawEditorialBack() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let safe = Specs.safeRect
    fill(P.offWhite, page)

    let left = safe.minX + 18
    let width = safe.width - 36
    drawText("COSTA BRAVA", rect: CGRect(x: left, y: safe.maxY - 18, width: width, height: 18), attrs: [
        .font: font("Avenir Next Bold", 15),
        .foregroundColor: P.deep
    ])
    drawText("MUSIC EVENTS", rect: CGRect(x: left, y: safe.maxY - 32, width: width, height: 18), attrs: [
        .font: font("Avenir Next Bold", 15),
        .foregroundColor: P.deep
    ])
    drawText(tagline, rect: CGRect(x: left, y: safe.maxY - 47, width: width, height: 16), attrs: [
        .font: font("Avenir Next Medium", 9.6),
        .foregroundColor: P.slate
    ])
    line(from: CGPoint(x: left, y: safe.maxY - 55), to: CGPoint(x: left + width, y: safe.maxY - 55), color: P.line)

    let phoneAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", 10.6),
        .foregroundColor: P.deep
    ]
    let infoAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", 8.8),
        .foregroundColor: P.deep
    ]
    drawText(phones, rect: CGRect(x: left, y: safe.maxY - 82, width: width, height: 14), attrs: phoneAttrs)
    drawText(email, rect: CGRect(x: left, y: safe.maxY - 102, width: width, height: 12), attrs: infoAttrs)
    drawText(web, rect: CGRect(x: left, y: safe.maxY - 120, width: width, height: 12), attrs: infoAttrs)
}

func drawMidnightFront() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let trim = Specs.trimRect
    if let bg = NSGradient(colors: [P.deep2, P.deep]) {
        bg.draw(in: page, angle: 90)
    }
    if let glow = NSGradient(colors: [P.aqua.withAlphaComponent(0.28), .clear]) {
        glow.draw(fromCenter: CGPoint(x: trim.minX + trim.width * 0.32, y: trim.midY + 6), radius: 0, toCenter: CGPoint(x: trim.minX + trim.width * 0.32, y: trim.midY + 6), radius: trim.width * 0.34, options: [])
    }
    if let glow2 = NSGradient(colors: [P.coral.withAlphaComponent(0.22), .clear]) {
        glow2.draw(fromCenter: CGPoint(x: trim.maxX - trim.width * 0.28, y: trim.midY + 8), radius: 0, toCenter: CGPoint(x: trim.maxX - trim.width * 0.28, y: trim.midY + 8), radius: trim.width * 0.30, options: [])
    }
    drawLogo(in: CGRect(x: trim.midX - 126, y: trim.midY - 52, width: 252, height: 252))
    centeredText("MUSIC FOR UNFORGETTABLE MOMENTS", point: CGPoint(x: trim.midX, y: trim.minY + 18), attrs: [
        .font: font("Avenir Next Demi Bold", 8.9),
        .foregroundColor: NSColor.white.withAlphaComponent(0.84),
        .kern: 2.2
    ])
}

func drawMidnightBack() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let safe = Specs.safeRect
    fill(P.deep, page)

    let topBand = CGRect(x: Specs.trimRect.minX, y: Specs.trimRect.maxY - 18, width: Specs.trimRect.width, height: 18)
    if let band = NSGradient(colors: [P.aqua.withAlphaComponent(0.95), P.amber.withAlphaComponent(0.95)]) {
        band.draw(in: topBand, angle: 0)
    }

    let left = safe.minX + 10
    let width = safe.width - 20
    drawText("COSTA BRAVA", rect: CGRect(x: left, y: safe.maxY - 18, width: width, height: 18), attrs: [
        .font: font("Avenir Next Bold", 14.5),
        .foregroundColor: NSColor.white
    ])
    drawText("MUSIC EVENTS", rect: CGRect(x: left, y: safe.maxY - 31, width: width, height: 18), attrs: [
        .font: font("Avenir Next Bold", 14.5),
        .foregroundColor: NSColor.white
    ])
    drawText(tagline, rect: CGRect(x: left, y: safe.maxY - 46, width: width, height: 14), attrs: [
        .font: font("Avenir Next Medium", 9.2),
        .foregroundColor: NSColor.white.withAlphaComponent(0.78)
    ])

    line(from: CGPoint(x: left, y: safe.maxY - 55), to: CGPoint(x: left + width, y: safe.maxY - 55), color: NSColor.white.withAlphaComponent(0.14))

    let phoneAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", 10.2),
        .foregroundColor: NSColor.white
    ]
    let infoAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", 8.6),
        .foregroundColor: NSColor.white.withAlphaComponent(0.90)
    ]
    drawText(phones, rect: CGRect(x: left, y: safe.maxY - 82, width: width, height: 14), attrs: phoneAttrs)
    drawText(email, rect: CGRect(x: left, y: safe.maxY - 102, width: width, height: 12), attrs: infoAttrs)
    drawText(web, rect: CGRect(x: left, y: safe.maxY - 120, width: width, height: 12), attrs: infoAttrs)
}

func drawSplitFront() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let trim = Specs.trimRect
    fill(P.offWhite, page)

    let leftPanel = CGRect(x: trim.minX, y: trim.minY, width: trim.width * 0.42, height: trim.height)
    fill(P.deep, leftPanel)
    if let g = NSGradient(colors: [P.aqua.withAlphaComponent(0.24), .clear]) {
        g.draw(fromCenter: CGPoint(x: leftPanel.midX, y: leftPanel.midY), radius: 0, toCenter: CGPoint(x: leftPanel.midX, y: leftPanel.midY), radius: leftPanel.width * 0.9, options: [])
    }

    if let accent = NSGradient(colors: [P.amber.withAlphaComponent(0.22), .clear]) {
        accent.draw(fromCenter: CGPoint(x: trim.maxX - 26, y: trim.maxY - 16), radius: 0, toCenter: CGPoint(x: trim.maxX - 26, y: trim.maxY - 16), radius: 80, options: [])
    }

    drawLogo(in: CGRect(x: trim.midX - 92, y: trim.midY - 52, width: 214, height: 214))

    let rightAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Bold", 10.4),
        .foregroundColor: P.deep,
        .kern: 1.8
    ]
    drawText("EVENTOS  CON  RITMO  Y  ESTILO", rect: CGRect(x: trim.minX + trim.width * 0.44, y: trim.minY + 18, width: trim.width * 0.46, height: 14), attrs: rightAttrs)
}

func drawSplitBack() {
    let page = CGRect(origin: .zero, size: Specs.pageSize)
    let trim = Specs.trimRect
    let safe = Specs.safeRect
    fill(P.offWhite, page)

    let leftPanel = CGRect(x: trim.minX, y: trim.minY, width: trim.width * 0.30, height: trim.height)
    fill(P.deep, leftPanel)
    if let band = NSGradient(colors: [P.aqua.withAlphaComponent(0.95), P.amber.withAlphaComponent(0.95)]) {
        band.draw(in: CGRect(x: leftPanel.maxX - 6, y: trim.minY, width: 6, height: trim.height), angle: -90)
    }

    drawText("COSTA\nBRAVA\nMUSIC\nEVENTS", rect: CGRect(x: leftPanel.minX + 16, y: safe.maxY - 56, width: leftPanel.width - 24, height: 86), attrs: [
        .font: font("Avenir Next Bold", 12.5),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(.left, 0)
    ])

    let x = leftPanel.maxX + 16
    let width = trim.maxX - x - 18
    drawText(tagline, rect: CGRect(x: x, y: safe.maxY - 18, width: width, height: 16), attrs: [
        .font: font("Avenir Next Medium", 9.4),
        .foregroundColor: P.slate
    ])
    line(from: CGPoint(x: x, y: safe.maxY - 28), to: CGPoint(x: x + width, y: safe.maxY - 28), color: P.line)
    drawText(phones, rect: CGRect(x: x, y: safe.maxY - 58, width: width, height: 14), attrs: [
        .font: font("Avenir Next Demi Bold", 9.5),
        .foregroundColor: P.deep
    ])
    drawText(email, rect: CGRect(x: x, y: safe.maxY - 80, width: width, height: 12), attrs: [
        .font: font("Avenir Next Medium", 8.5),
        .foregroundColor: P.deep
    ])
    drawText(web, rect: CGRect(x: x, y: safe.maxY - 98, width: width, height: 12), attrs: [
        .font: font("Avenir Next Medium", 8.5),
        .foregroundColor: P.deep
    ])
}

func drawFront(for variant: Variant) {
    switch variant.slug {
    case "editorial": drawEditorialFront()
    case "midnight": drawMidnightFront()
    default: drawSplitFront()
    }
}

func drawBack(for variant: Variant) {
    switch variant.slug {
    case "editorial": drawEditorialBack()
    case "midnight": drawMidnightBack()
    default: drawSplitBack()
    }
}

func renderPDF(url: URL, draw: () -> Void) throws {
    var media = CGRect(origin: .zero, size: Specs.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &media, nil) else { throw NSError(domain: "render", code: 1) }
    ctx.beginPDFPage(nil)
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    draw()
    NSGraphicsContext.restoreGraphicsState()
    ctx.endPDFPage()
    ctx.closePDF()
}

func renderCombinedPDF(url: URL, front: @escaping () -> Void, back: @escaping () -> Void) throws {
    var media = CGRect(origin: .zero, size: Specs.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &media, nil) else { throw NSError(domain: "render", code: 2) }
    for page in [front, back] {
        ctx.beginPDFPage(nil)
        let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ns
        page()
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
    }
    ctx.closePDF()
}

func renderPNG(url: URL, draw: () -> Void) throws {
    let pxWidth = Int((Specs.pageWidthMM / 25.4 * Specs.dpi).rounded())
    let pxHeight = Int((Specs.pageHeightMM / 25.4 * Specs.dpi).rounded())
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pxWidth, pixelsHigh: pxHeight, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        throw NSError(domain: "render", code: 3)
    }
    rep.size = NSSize(width: Specs.pageWidthMM * Specs.mmToPt, height: Specs.pageHeightMM * Specs.mmToPt)
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else { throw NSError(domain: "render", code: 4) }
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns
    draw()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { throw NSError(domain: "render", code: 5) }
    try data.write(to: url)
}

for variant in variants {
    let frontPDF = outDir.appendingPathComponent("cbme-business-card-\(variant.slug)-front-print.pdf")
    let backPDF = outDir.appendingPathComponent("cbme-business-card-\(variant.slug)-back-print.pdf")
    let combinedPDF = outDir.appendingPathComponent("cbme-business-card-\(variant.slug)-print.pdf")
    let frontPNG = outDir.appendingPathComponent("cbme-business-card-\(variant.slug)-front-preview.png")
    let backPNG = outDir.appendingPathComponent("cbme-business-card-\(variant.slug)-back-preview.png")

    try renderPDF(url: frontPDF) { drawFront(for: variant) }
    try renderPDF(url: backPDF) { drawBack(for: variant) }
    try renderCombinedPDF(url: combinedPDF, front: { drawFront(for: variant) }, back: { drawBack(for: variant) })
    try renderPNG(url: frontPNG) { drawFront(for: variant) }
    try renderPNG(url: backPNG) { drawBack(for: variant) }

    print(frontPDF.path)
    print(backPDF.path)
    print(combinedPDF.path)
}
