import AppKit
import CoreImage
import CoreGraphics
import Foundation

struct CardSpecs {
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
    static let safeInset: CGFloat = 5 * mmToPt
    static let safeRect = trimRect.insetBy(dx: safeInset, dy: safeInset)
}

struct Palette {
    static let deep = NSColor(calibratedRed: 6 / 255, green: 20 / 255, blue: 40 / 255, alpha: 1)
    static let aqua = NSColor(calibratedRed: 34 / 255, green: 211 / 255, blue: 238 / 255, alpha: 1)
    static let teal = NSColor(calibratedRed: 104 / 255, green: 206 / 255, blue: 178 / 255, alpha: 1)
    static let coral = NSColor(calibratedRed: 246 / 255, green: 121 / 255, blue: 87 / 255, alpha: 1)
    static let amber = NSColor(calibratedRed: 251 / 255, green: 191 / 255, blue: 36 / 255, alpha: 1)
    static let offWhite = NSColor(calibratedRed: 247 / 255, green: 245 / 255, blue: 240 / 255, alpha: 1)
    static let slate = NSColor(calibratedRed: 66 / 255, green: 76 / 255, blue: 96 / 255, alpha: 1)
    static let line = NSColor(calibratedRed: 220 / 255, green: 226 / 255, blue: 236 / 255, alpha: 1)
}

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outputDir = cwd.appendingPathComponent("assets/print", isDirectory: true)
let logoURL = cwd.appendingPathComponent("assets/img/logo-transparente.png")

try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let logo = NSImage(contentsOf: logoURL) else {
    fputs("No se ha podido cargar el logo en \(logoURL.path)\n", stderr)
    exit(1)
}

let phone1 = "687 962 905"
let phone2 = "619 840 206"
let phonesCombined = "\(phone1) / \(phone2)"
let email = "info@costabravamusicevents.com"
let web = "www.costabravamusicevents.com"
let instagram = "@costabrava_music_events"
let tagline = "Música a medida para eventos"
let qrContact = "https://www.costabravamusicevents.com"

func font(_ name: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    if let custom = NSFont(name: name, size: size) {
        return custom
    }
    return NSFont.systemFont(ofSize: size, weight: weight)
}

func paragraph(alignment: NSTextAlignment = .left, lineSpacing: CGFloat = 0) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineSpacing = lineSpacing
    return style
}

func drawText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

func drawCenteredText(_ text: String, center: CGPoint, attributes: [NSAttributedString.Key: Any]) {
    let attr = NSAttributedString(string: text, attributes: attributes)
    let size = attr.size()
    let rect = CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    attr.draw(in: rect)
}

func drawQRCode(_ payload: String, in rect: CGRect) {
    guard
        let data = payload.data(using: .utf8),
        let filter = CIFilter(name: "CIQRCodeGenerator")
    else { return }

    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")

    guard let output = filter.outputImage else { return }

    let bounds = output.extent.integral
    let scaleX = rect.width / bounds.width
    let scaleY = rect.height / bounds.height
    let transformed = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    let ciContext = CIContext(options: nil)
    guard let cgImage = ciContext.createCGImage(transformed, from: transformed.extent) else { return }

    let qrInsetRect = rect.insetBy(dx: 3, dy: 3)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).fill()
    NSColor(calibratedWhite: 0.88, alpha: 1).setStroke()
    let border = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
    border.lineWidth = 0.8
    border.stroke()

    if let cg = NSGraphicsContext.current?.cgContext {
        cg.interpolationQuality = .none
        cg.draw(cgImage, in: qrInsetRect)
    }
}

func drawFront(in ctx: CGContext) {
    let pageRect = CGRect(origin: .zero, size: CardSpecs.pageSize)
    let trim = CardSpecs.trimRect

    ctx.setFillColor(Palette.offWhite.cgColor)
    ctx.fill(pageRect)

    if let aquaGradient = NSGradient(colors: [Palette.aqua.withAlphaComponent(0.17), Palette.aqua.withAlphaComponent(0.0)]) {
        aquaGradient.draw(fromCenter: CGPoint(x: trim.minX + trim.width * 0.22, y: trim.maxY - 12),
                          radius: 0,
                          toCenter: CGPoint(x: trim.minX + trim.width * 0.22, y: trim.maxY - 12),
                          radius: trim.width * 0.34,
                          options: [])
    }
    if let amberGradient = NSGradient(colors: [Palette.amber.withAlphaComponent(0.15), Palette.amber.withAlphaComponent(0.0)]) {
        amberGradient.draw(fromCenter: CGPoint(x: trim.maxX - trim.width * 0.18, y: trim.minY + 10),
                           radius: 0,
                           toCenter: CGPoint(x: trim.maxX - trim.width * 0.18, y: trim.minY + 10),
                           radius: trim.width * 0.31,
                           options: [])
    }

    let logoWidth = trim.width * 0.80
    let logoRect = CGRect(
        x: trim.midX - logoWidth / 2,
        y: trim.midY - logoWidth / 2 + 28,
        width: logoWidth,
        height: logoWidth
    )
    logo.draw(in: logoRect)

    let baselineY = trim.minY + 30
    let path = NSBezierPath()
    path.move(to: CGPoint(x: trim.minX + 30, y: baselineY))
    path.line(to: CGPoint(x: trim.maxX - 30, y: baselineY))
    Palette.deep.withAlphaComponent(0.14).setStroke()
    path.lineWidth = 0.8
    path.stroke()

    let strapAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 9.2),
        .foregroundColor: Palette.slate,
        .kern: 2.0,
        .paragraphStyle: paragraph(alignment: .center)
    ]
    drawCenteredText("DJ  LIVE MUSIC  SOUND  LIGHTING", center: CGPoint(x: trim.midX, y: trim.minY + 18), attributes: strapAttrs)
}

func drawDivider(x: CGFloat, y: CGFloat, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: x, y: y))
    path.line(to: CGPoint(x: x + width, y: y))
    Palette.line.setStroke()
    path.lineWidth = 0.8
    path.stroke()
}

func drawContactBlock(label: String, value: String, x: CGFloat, topY: CGFloat, width: CGFloat) {
    let labelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 7.2),
        .foregroundColor: Palette.slate.withAlphaComponent(0.82),
        .kern: 1.2
    ]
    let valueAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.8),
        .foregroundColor: Palette.deep,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 0.5)
    ]
    drawText(label, in: CGRect(x: x, y: topY, width: width, height: 10), attributes: labelAttrs)
    drawText(value, in: CGRect(x: x, y: topY - 17, width: width, height: 16), attributes: valueAttrs)
}

func drawBack(in ctx: CGContext) {
    let pageRect = CGRect(origin: .zero, size: CardSpecs.pageSize)
    let trim = CardSpecs.trimRect
    let safe = CardSpecs.safeRect

    ctx.setFillColor(Palette.offWhite.cgColor)
    ctx.fill(pageRect)

    let accentWidth: CGFloat = 11
    let accentRect = CGRect(x: trim.minX, y: trim.minY, width: accentWidth, height: trim.height)
    if let accent = NSGradient(colors: [Palette.aqua.withAlphaComponent(0.98), Palette.teal.withAlphaComponent(0.95), Palette.coral.withAlphaComponent(0.94), Palette.amber.withAlphaComponent(0.98)]) {
        accent.draw(in: accentRect, angle: -90)
    }

    let innerLeft = safe.minX + 8
    let contentWidth = safe.width - 16
    let qrSize: CGFloat = 48
    let qrRect = CGRect(x: safe.maxX - qrSize - 6, y: safe.minY + 2, width: qrSize, height: qrSize)
    drawQRCode(qrContact, in: qrRect)
    let textLeft = innerLeft
    let textWidth = safe.maxX - textLeft - 6

    let brandAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Bold", size: 15),
        .foregroundColor: Palette.deep
    ]
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 9.4),
        .foregroundColor: Palette.slate
    ]

    drawText("COSTA BRAVA", in: CGRect(x: textLeft, y: safe.maxY - 18, width: textWidth, height: 18), attributes: brandAttrs)
    drawText("MUSIC EVENTS", in: CGRect(x: textLeft, y: safe.maxY - 31, width: textWidth, height: 16), attributes: brandAttrs)
    drawText(tagline, in: CGRect(x: textLeft, y: safe.maxY - 46, width: textWidth, height: 14), attributes: subAttrs)

    drawDivider(x: innerLeft, y: safe.maxY - 58, width: contentWidth)

    let valueX = innerLeft
    let valueWidth = contentWidth
    let rowTop = safe.maxY - 80
    let rowGap: CGFloat = 15
    let phoneAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 9.6),
        .foregroundColor: Palette.deep
    ]
    let contactAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 8.3),
        .foregroundColor: Palette.deep
    ]

    let rows: [(String, [NSAttributedString.Key: Any])] = [
        (phonesCombined, phoneAttrs),
        (email, contactAttrs),
        (web, contactAttrs),
        (instagram, contactAttrs)
    ]

    for (index, row) in rows.enumerated() {
        let y = rowTop - CGFloat(index) * rowGap
        drawText(row.0, in: CGRect(x: valueX, y: y, width: valueWidth, height: 12), attributes: row.1)
    }
}

func renderPDF(to url: URL, draw: (CGContext) -> Void) throws {
    var mediaBox = CGRect(origin: .zero, size: CardSpecs.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "card", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF \(url.lastPathComponent)"])
    }
    ctx.beginPDFPage(nil)
    let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    draw(ctx)
    NSGraphicsContext.restoreGraphicsState()
    ctx.endPDFPage()
    ctx.closePDF()
}

func renderPNG(to url: URL, draw: (CGContext) -> Void) throws {
    let pxWidth = Int((CardSpecs.pageWidthMM / 25.4 * CardSpecs.dpi).rounded())
    let pxHeight = Int((CardSpecs.pageHeightMM / 25.4 * CardSpecs.dpi).rounded())
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pxWidth,
        pixelsHigh: pxHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "card", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el bitmap"])
    }

    rep.size = NSSize(width: CardSpecs.pageWidthMM * 72.0 / 25.4, height: CardSpecs.pageHeightMM * 72.0 / 25.4)

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        throw NSError(domain: "card", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el contexto PNG"])
    }

    ctx.interpolationQuality = .high

    let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    draw(ctx)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "card", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo exportar el PNG"])
    }
    try data.write(to: url)
}

func renderCombinedPDF(to url: URL) throws {
    var mediaBox = CGRect(origin: .zero, size: CardSpecs.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "card", code: 5, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF combinado"])
    }

    for drawer in [drawFront, drawBack] {
        ctx.beginPDFPage(nil)
        let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        drawer(ctx)
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
    }

    ctx.closePDF()
}

let frontPDF = outputDir.appendingPathComponent("cbme-business-card-front-print.pdf")
let backPDF = outputDir.appendingPathComponent("cbme-business-card-back-print.pdf")
let combinedPDF = outputDir.appendingPathComponent("cbme-business-card-print.pdf")
let frontPNG = outputDir.appendingPathComponent("cbme-business-card-front-preview.png")
let backPNG = outputDir.appendingPathComponent("cbme-business-card-back-preview.png")

try renderPDF(to: frontPDF, draw: drawFront)
try renderPDF(to: backPDF, draw: drawBack)
try renderCombinedPDF(to: combinedPDF)
try renderPNG(to: frontPNG, draw: drawFront)
try renderPNG(to: backPNG, draw: drawBack)

print(frontPDF.path)
print(backPDF.path)
print(combinedPDF.path)
print(frontPNG.path)
print(backPNG.path)
