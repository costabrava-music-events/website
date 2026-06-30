import AppKit
import CoreImage
import CoreGraphics
import Foundation

struct TrifoldSpec {
    static let dpi: CGFloat = 300
    static let mmToPt: CGFloat = 72.0 / 25.4
    static let pageWidthMM: CGFloat = 297
    static let pageHeightMM: CGFloat = 210
    static let pageSize = CGSize(width: pageWidthMM * mmToPt, height: pageHeightMM * mmToPt)
    static let panelWidth = pageSize.width / 3.0
    static let safeInset: CGFloat = 8 * mmToPt

    static func panelRect(_ index: Int) -> CGRect {
        CGRect(x: CGFloat(index) * panelWidth, y: 0, width: panelWidth, height: pageSize.height)
    }

    static func safeRect(_ index: Int) -> CGRect {
        panelRect(index).insetBy(dx: safeInset, dy: safeInset)
    }
}

struct Palette {
    static let night = NSColor(calibratedRed: 7 / 255, green: 20 / 255, blue: 39 / 255, alpha: 1)
    static let navy = NSColor(calibratedRed: 12 / 255, green: 35 / 255, blue: 67 / 255, alpha: 1)
    static let cyan = NSColor(calibratedRed: 34 / 255, green: 211 / 255, blue: 238 / 255, alpha: 1)
    static let teal = NSColor(calibratedRed: 70 / 255, green: 196 / 255, blue: 175 / 255, alpha: 1)
    static let amber = NSColor(calibratedRed: 248 / 255, green: 191 / 255, blue: 95 / 255, alpha: 1)
    static let coral = NSColor(calibratedRed: 247 / 255, green: 130 / 255, blue: 104 / 255, alpha: 1)
    static let mist = NSColor(calibratedRed: 239 / 255, green: 245 / 255, blue: 248 / 255, alpha: 1)
    static let paper = NSColor(calibratedRed: 250 / 255, green: 247 / 255, blue: 241 / 255, alpha: 1)
    static let slate = NSColor(calibratedRed: 90 / 255, green: 104 / 255, blue: 121 / 255, alpha: 1)
    static let line = NSColor(calibratedRed: 211 / 255, green: 220 / 255, blue: 229 / 255, alpha: 1)
}

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outputDir = cwd.appendingPathComponent("assets/print", isDirectory: true)
let logoURL = cwd.appendingPathComponent("assets/img/logo-hero-white-text.png")

/// Uso: `swift generate_trifold_private_events.swift` (imagen por defecto)
///       `swift … [rutaImagenRelativaAlRepo] [sufijoSalida]` → previews con sufijo en el nombre de archivo.
let cliArgs = Array(CommandLine.arguments.dropFirst())
func resolveAssetPath(_ arg: String) -> URL {
    if arg.hasPrefix("/") { return URL(fileURLWithPath: arg) }
    return cwd.appendingPathComponent(arg)
}
let defaultEventImageURL = cwd.appendingPathComponent("assets/img/abstract-venue-card.png")
let eventPhotoURL: URL = {
    guard let first = cliArgs.first, !first.isEmpty else { return defaultEventImageURL }
    let candidate = resolveAssetPath(first)
    return fm.fileExists(atPath: candidate.path) ? candidate : defaultEventImageURL
}()
let outputSlug: String = {
    guard cliArgs.count >= 2 else { return "" }
    let s = cliArgs[1].replacingOccurrences(of: " ", with: "-")
    return s
}()

try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let logo = NSImage(contentsOf: logoURL) else {
    fputs("No se ha podido cargar el logo en \(logoURL.path)\n", stderr)
    exit(1)
}

let eventPhoto = NSImage(contentsOf: eventPhotoURL)

let brand = "Costa Brava Music Events"
let title = "Tu partner de confianza\npara tu evento"
let subtitle = "Música, sonido e iluminación para villas, terrazas, jardines y celebraciones con personalidad."
let contactCopy = "Cuéntanos la fecha, el espacio y el tipo de evento. Te preparamos una propuesta clara, elegante y adaptada al ambiente que buscas."
let web = "www.costabravamusicevents.com"
let instagram = "@costabrava_music_events"
let email = "info@costabravamusicevents.com"
let phone1 = "687 962 905"
let phone2 = "619 840 206"
let qrURL = "https://www.costabravamusicevents.com"

func font(_ name: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func paragraph(alignment: NSTextAlignment = .left, lineSpacing: CGFloat = 0, minimumLineHeight: CGFloat = 0) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineSpacing = lineSpacing
    style.minimumLineHeight = minimumLineHeight
    return style
}

func drawText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
    NSAttributedString(string: text, attributes: attributes).draw(
        with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
}

func drawCenteredText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
    let attr = NSAttributedString(string: text, attributes: attributes)
    let size = attr.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading]).size
    let drawRect = CGRect(
        x: rect.midX - size.width / 2,
        y: rect.midY - size.height / 2,
        width: size.width,
        height: size.height
    )
    attr.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func strokeRoundedRect(_ rect: CGRect, radius: CGFloat, color: NSColor, lineWidth: CGFloat = 1) {
    color.setStroke()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = lineWidth
    path.stroke()
}

func drawRoundedGradient(in rect: CGRect, radius: CGFloat, colors: [NSColor], angle: CGFloat) {
    guard let gradient = NSGradient(colors: colors) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    gradient.draw(in: rect, angle: angle)
    NSGraphicsContext.restoreGraphicsState()
}

func drawImageAspectFill(_ image: NSImage, in rect: CGRect, cornerRadius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    let imageSize = image.size
    guard imageSize.width > 0, imageSize.height > 0 else { return }

    let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
    let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let drawRect = CGRect(
        x: rect.midX - drawSize.width / 2,
        y: rect.midY - drawSize.height / 2,
        width: drawSize.width,
        height: drawSize.height
    )

    image.draw(in: drawRect)
    NSGraphicsContext.restoreGraphicsState()
}

func drawOrb(center: CGPoint, radius: CGFloat, colors: [NSColor]) {
    guard let gradient = NSGradient(colors: colors) else { return }
    gradient.draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
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

    fillRoundedRect(rect, radius: 8, color: .white)
    strokeRoundedRect(rect, radius: 8, color: Palette.line, lineWidth: 0.8)

    if let cg = NSGraphicsContext.current?.cgContext {
        cg.interpolationQuality = .none
        cg.draw(cgImage, in: rect.insetBy(dx: 5, dy: 5))
    }
}

func drawBulletRow(symbol: String, title: String, text: String, rect: CGRect, dark: Bool = false) {
    let circleColor = dark ? Palette.cyan : Palette.navy
    let titleColor = dark ? NSColor.white : Palette.navy
    let bodyColor = dark ? NSColor.white.withAlphaComponent(0.84) : Palette.slate

    let dotRect = CGRect(x: rect.minX, y: rect.maxY - 16, width: 22, height: 22)
    fillRoundedRect(dotRect, radius: 11, color: circleColor.withAlphaComponent(dark ? 0.22 : 0.12))
    drawCenteredText(symbol, in: dotRect, attributes: [
        .font: font("Avenir Next Bold", size: 10),
        .foregroundColor: circleColor
    ])

    drawText(title, in: CGRect(x: rect.minX + 30, y: rect.maxY - 16, width: rect.width - 30, height: 16), attributes: [
        .font: font("Avenir Next Demi Bold", size: 11.4),
        .foregroundColor: titleColor
    ])

    drawText(text, in: CGRect(x: rect.minX + 30, y: rect.minY, width: rect.width - 30, height: rect.height - 20), attributes: [
        .font: font("Avenir Next Medium", size: 9.4),
        .foregroundColor: bodyColor,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.5)
    ])
}

func drawStageCard(symbol: String, title: String, text: String, rect: CGRect) {
    fillRoundedRect(rect, radius: 16, color: NSColor.white.withAlphaComponent(0.08))

    let dotRect = CGRect(x: rect.minX + 14, y: rect.maxY - 34, width: 24, height: 24)
    fillRoundedRect(dotRect, radius: 12, color: Palette.cyan.withAlphaComponent(0.22))
    drawCenteredText(symbol, in: dotRect, attributes: [
        .font: font("Avenir Next Bold", size: 10.5),
        .foregroundColor: Palette.cyan
    ])

    drawText(title, in: CGRect(x: rect.minX + 46, y: rect.maxY - 28, width: rect.width - 58, height: 18), attributes: [
        .font: font("Avenir Next Demi Bold", size: 10.0),
        .foregroundColor: NSColor.white
    ])

    drawText(text, in: CGRect(x: rect.minX + 46, y: rect.minY + 8, width: rect.width - 58, height: rect.height - 42), attributes: [
        .font: font("Avenir Next Medium", size: 7.8),
        .foregroundColor: NSColor.white.withAlphaComponent(0.84),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.2)
    ])
}

func drawBulletListItem(_ text: String, rect: CGRect) {
    let dotRect = CGRect(x: rect.minX, y: rect.maxY - 16, width: 20, height: 20)
    fillRoundedRect(dotRect, radius: 10, color: Palette.navy.withAlphaComponent(0.08))
    drawCenteredText("•", in: dotRect, attributes: [
        .font: font("Avenir Next Bold", size: 11.2),
        .foregroundColor: Palette.navy
    ])

    drawText(text, in: CGRect(x: rect.minX + 28, y: rect.minY, width: rect.width - 28, height: rect.height), attributes: [
        .font: font("Avenir Next Demi Bold", size: 8.9),
        .foregroundColor: Palette.navy,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 0.4)
    ])
}

func drawPill(_ text: String, origin: CGPoint, dark: Bool = false) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.8),
        .foregroundColor: dark ? NSColor.white : Palette.navy
    ]
    let attr = NSAttributedString(string: text, attributes: attrs)
    let size = attr.size()
    let rect = CGRect(x: origin.x, y: origin.y, width: size.width + 18, height: 20)
    fillRoundedRect(rect, radius: 10, color: (dark ? Palette.cyan.withAlphaComponent(0.18) : Palette.mist))
    attr.draw(in: CGRect(x: rect.minX + 9, y: rect.minY + 4, width: size.width, height: size.height))
}

func drawCompactPill(_ text: String, origin: CGPoint, dark: Bool = false) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 9.2),
        .foregroundColor: dark ? NSColor.white : Palette.navy
    ]
    let attr = NSAttributedString(string: text, attributes: attrs)
    let size = attr.size()
    let rect = CGRect(x: origin.x, y: origin.y, width: size.width + 14, height: 22)
    fillRoundedRect(rect, radius: 11, color: (dark ? Palette.cyan.withAlphaComponent(0.18) : Palette.mist))
    attr.draw(in: CGRect(x: rect.minX + 7, y: rect.minY + 4, width: size.width, height: size.height))
}

func drawOutside(_ ctx: CGContext) {
    let pageRect = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    let left = TrifoldSpec.safeRect(0)
    let middle = TrifoldSpec.safeRect(1)
    let right = TrifoldSpec.safeRect(2)
    let leftContent = left.insetBy(dx: 14, dy: 14)
    let middleContent = middle.insetBy(dx: 16, dy: 14)
    let rightContent = right.insetBy(dx: 16, dy: 16)

    ctx.setFillColor(Palette.night.cgColor)
    ctx.fill(pageRect)

    drawOrb(center: CGPoint(x: pageRect.width * 0.18, y: pageRect.height * 0.80), radius: 180, colors: [Palette.cyan.withAlphaComponent(0.18), .clear])
    drawOrb(center: CGPoint(x: pageRect.width * 0.74, y: pageRect.height * 0.72), radius: 220, colors: [Palette.amber.withAlphaComponent(0.18), .clear])
    drawOrb(center: CGPoint(x: pageRect.width * 0.88, y: pageRect.height * 0.30), radius: 200, colors: [Palette.coral.withAlphaComponent(0.20), .clear])

    let topBand = CGRect(x: 0, y: pageRect.height - 56, width: pageRect.width, height: 56)
    if let band = NSGradient(colors: [Palette.navy.withAlphaComponent(0.0), Palette.navy.withAlphaComponent(0.36)]) {
        band.draw(in: topBand, angle: -90)
    }

    let middlePanelRect = CGRect(x: middle.minX, y: middle.minY, width: middle.width, height: middle.height)

    fillRoundedRect(CGRect(x: left.minX, y: left.minY, width: left.width, height: left.height), radius: 24, color: Palette.paper)
    if let photo = eventPhoto {
        drawImageAspectFill(photo, in: middlePanelRect, cornerRadius: 24)
        fillRoundedRect(middlePanelRect, radius: 24, color: Palette.night.withAlphaComponent(0.56))
    } else {
        fillRoundedRect(middlePanelRect, radius: 24, color: NSColor.white.withAlphaComponent(0.06))
    }
    fillRoundedRect(CGRect(x: right.minX, y: right.minY, width: right.width, height: right.height), radius: 24, color: NSColor.black.withAlphaComponent(0.10))

    let leftLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.6),
        .foregroundColor: Palette.slate,
        .kern: 1.4
    ]
    let leftTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 18),
        .foregroundColor: Palette.navy
    ]
    let leftBodyAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.2),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ]

    drawText("CONTACTO", in: CGRect(x: leftContent.minX, y: leftContent.maxY - 10, width: leftContent.width, height: 12), attributes: leftLabelAttrs)
    drawText("Hablemos", in: CGRect(x: leftContent.minX, y: leftContent.maxY - 48, width: leftContent.width, height: 28), attributes: leftTitleAttrs)
    drawText(contactCopy, in: CGRect(x: leftContent.minX, y: leftContent.maxY - 128, width: leftContent.width, height: 76), attributes: leftBodyAttrs)

    let contacts = [
        phone1,
        phone2,
        email,
        web,
        instagram
    ]
    for (index, item) in contacts.enumerated() {
        drawText(item, in: CGRect(x: leftContent.minX, y: leftContent.maxY - 164 - CGFloat(index) * 22, width: leftContent.width, height: 18), attributes: [
            .font: font(index < 2 ? "Avenir Next Demi Bold" : "Avenir Next Medium", size: index < 2 ? 10.4 : 9.8),
            .foregroundColor: Palette.navy
        ])
    }

    let qrRect = CGRect(x: left.midX - 39, y: leftContent.minY, width: 78, height: 78)
    drawText("Escanea y descubre\nmás sobre nosotros", in: CGRect(x: leftContent.minX, y: qrRect.maxY + 10, width: leftContent.width, height: 40), attributes: [
        .font: font("Avenir Next Medium", size: 9.6),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .center, lineSpacing: 1.6)
    ])
    drawQRCode(qrURL, in: qrRect)

    let middleLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.6),
        .foregroundColor: NSColor.white.withAlphaComponent(0.72),
        .kern: 1.8
    ]
    let middleTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 14.8),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.0, minimumLineHeight: 16)
    ]
    let middleBodyAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.1),
        .foregroundColor: NSColor.white.withAlphaComponent(0.82),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ]

    drawText("TRAYECTORIA", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 10, width: middleContent.width, height: 12), attributes: middleLabelAttrs)
    drawText("Experiencia en eventos", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 96, width: middleContent.width, height: 28), attributes: middleTitleAttrs)
    drawText("Con más de una década organizando eventos musicales, en Costa Brava Music Events combinamos solvencia técnica impecable y criterio musical exigente.", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 168, width: middleContent.width, height: 78), attributes: middleBodyAttrs)

    let refLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.4),
        .foregroundColor: NSColor.white.withAlphaComponent(0.70),
        .kern: 1.6
    ]
    drawText("REFERENCIAS", in: CGRect(x: middleContent.minX, y: middleContent.minY + 336, width: middleContent.width, height: 12), attributes: refLabelAttrs)
    drawCompactPill("FC Barcelona", origin: CGPoint(x: middleContent.minX, y: middleContent.minY + 308), dark: true)
    drawCompactPill("Sea Sea Club", origin: CGPoint(x: middleContent.minX + 88, y: middleContent.minY + 308), dark: true)
    drawCompactPill("Red Fish", origin: CGPoint(x: middleContent.minX, y: middleContent.minY + 282), dark: true)
    drawCompactPill("BCN en las Alturas", origin: CGPoint(x: middleContent.minX + 66, y: middleContent.minY + 282), dark: true)
    drawCompactPill("Can Marc", origin: CGPoint(x: middleContent.minX, y: middleContent.minY + 256), dark: true)
    drawCompactPill("Cap Sa Sal", origin: CGPoint(x: middleContent.minX + 66, y: middleContent.minY + 256), dark: true)
    drawCompactPill("La Ruïna", origin: CGPoint(x: middleContent.minX + 132, y: middleContent.minY + 256), dark: true)
    drawCompactPill("Lincoln", origin: CGPoint(x: middleContent.minX, y: middleContent.minY + 230), dark: true)
    drawCompactPill("Venteo Platja d'Aro", origin: CGPoint(x: middleContent.minX + 58, y: middleContent.minY + 230), dark: true)
    drawCompactPill("Bellport", origin: CGPoint(x: middleContent.minX, y: middleContent.minY + 204), dark: true)
    drawCompactPill("Ajuntament de Palamós", origin: CGPoint(x: middleContent.minX + 66, y: middleContent.minY + 204), dark: true)

    let rightLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 9.2),
        .foregroundColor: NSColor.white.withAlphaComponent(0.70),
        .kern: 1.8
    ]
    let rightTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 20.5),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.8, minimumLineHeight: 22)
    ]
    let rightBodyAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.6),
        .foregroundColor: NSColor.white.withAlphaComponent(0.84),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ]

    let logoSize: CGFloat = 214
    let logoRect = CGRect(
        x: right.midX - logoSize / 2,
        y: rightContent.maxY - 182,
        width: logoSize,
        height: logoSize
    )
    logo.draw(in: logoRect)

    drawText(brand.uppercased(), in: CGRect(x: rightContent.minX, y: rightContent.maxY - 214, width: rightContent.width, height: 14), attributes: rightLabelAttrs)
    drawText(title, in: CGRect(x: rightContent.minX, y: rightContent.maxY - 344, width: rightContent.width, height: 132), attributes: rightTitleAttrs)
    drawText(subtitle, in: CGRect(x: rightContent.minX, y: rightContent.maxY - 418, width: rightContent.width, height: 96), attributes: [
        .font: font("Avenir Next Demi Bold", size: 11.8),
        .foregroundColor: NSColor.white.withAlphaComponent(0.88),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2.2)
    ])

}

func drawInside(_ ctx: CGContext) {
    let pageRect = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    let left = TrifoldSpec.safeRect(0)
    let middle = TrifoldSpec.safeRect(1)
    let right = TrifoldSpec.safeRect(2)
    let middleContent = middle.insetBy(dx: 16, dy: 16)

    ctx.setFillColor(Palette.paper.cgColor)
    ctx.fill(pageRect)

    drawOrb(center: CGPoint(x: pageRect.width * 0.15, y: pageRect.height * 0.84), radius: 160, colors: [Palette.cyan.withAlphaComponent(0.10), .clear])
    drawOrb(center: CGPoint(x: pageRect.width * 0.88, y: pageRect.height * 0.18), radius: 170, colors: [Palette.amber.withAlphaComponent(0.14), .clear])

    let middlePanelRect = CGRect(x: middle.minX, y: middle.minY, width: middle.width, height: middle.height)
    if let photo = eventPhoto {
        drawImageAspectFill(photo, in: middlePanelRect, cornerRadius: 24)
        fillRoundedRect(middlePanelRect, radius: 24, color: Palette.night.withAlphaComponent(0.50))
        drawRoundedGradient(
            in: middlePanelRect,
            radius: 24,
            colors: [Palette.amber.withAlphaComponent(0.14), Palette.coral.withAlphaComponent(0.08), .clear],
            angle: -35
        )
    } else {
        fillRoundedRect(middlePanelRect, radius: 24, color: Palette.night)
        drawRoundedGradient(
            in: middlePanelRect,
            radius: 24,
            colors: [Palette.cyan.withAlphaComponent(0.18), .clear],
            angle: -90
        )
    }

    let smallLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.4),
        .foregroundColor: Palette.slate,
        .kern: 1.6
    ]
    let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 17.4),
        .foregroundColor: Palette.navy
    ]

    drawText("QUÉ APORTAMOS", in: CGRect(x: left.minX, y: left.maxY - 16, width: left.width, height: 12), attributes: smallLabelAttrs)
    drawText("Oficio, lectura de sala y criterio de evento", in: CGRect(x: left.minX, y: left.maxY - 78, width: left.width, height: 56), attributes: sectionTitleAttrs)
    drawText("Llevamos al evento la experiencia de haber trabajado en celebraciones privadas, venues, clubs y espacios institucionales donde la ejecución tiene que salir bien de verdad.", in: CGRect(x: left.minX, y: left.maxY - 150, width: left.width, height: 74), attributes: [
        .font: font("Avenir Next Medium", size: 10.1),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ])

    drawBulletRow(symbol: "01", title: "Dirección musical personalizada", text: "Adaptamos el recorrido musical al tono del evento, al espacio y al tipo de invitados.", rect: CGRect(x: left.minX, y: left.maxY - 228, width: left.width, height: 60))
    drawBulletRow(symbol: "02", title: "Solvencia técnica", text: "Sonido, niveles y ejecución pensados para que todo funcione con limpieza y seguridad.", rect: CGRect(x: left.minX, y: left.maxY - 298, width: left.width, height: 54))
    drawBulletRow(symbol: "03", title: "Experiencia en venues reales", text: "Trabajar en espacios exigentes da criterio para resolver con calma y leer el momento.", rect: CGRect(x: left.minX, y: left.maxY - 368, width: left.width, height: 54))
    drawBulletRow(symbol: "04", title: "Visión de conjunto", text: "Nos coordinamos con venue y proveedores para que la música acompañe el evento.", rect: CGRect(x: left.minX, y: left.maxY - 438, width: left.width, height: 54))

    let darkLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.4),
        .foregroundColor: NSColor.white.withAlphaComponent(0.70),
        .kern: 1.6
    ]
    let darkTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 17.8),
        .foregroundColor: NSColor.white
    ]
    let darkBodyAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.0),
        .foregroundColor: NSColor.white.withAlphaComponent(0.82),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ]

    drawText("REFERENCIAS", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 4, width: middleContent.width, height: 12), attributes: darkLabelAttrs)
    drawText("Espacios y eventos que dan contexto al proyecto", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 86, width: middleContent.width, height: 70), attributes: darkTitleAttrs)
    let stageCardWidth = middleContent.width
    let stage1 = CGRect(x: middleContent.minX, y: middleContent.maxY - 208, width: stageCardWidth, height: 74)
    let stage2 = CGRect(x: middleContent.minX, y: middleContent.maxY - 290, width: stageCardWidth, height: 74)
    let stage3 = CGRect(x: middleContent.minX, y: middleContent.maxY - 380, width: stageCardWidth, height: 84)

    drawStageCard(symbol: "A", title: "Gran formato y corporativo", text: "FC Barcelona aporta coordinación y técnica en máxima exigencia.", rect: stage1)
    drawStageCard(symbol: "B", title: "Celebración privada y venue", text: "Cap Sa Sal, Can Marc y Bellport conectan con bodas y eventos cuidados.", rect: stage2)
    drawStageCard(symbol: "C", title: "Nightlife y acto público", text: "Lincoln, Venteo, Red Fish, Sea Sea Club y Ajuntament de Palamós muestran versatilidad.", rect: stage3)

    let rightTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 16.2),
        .foregroundColor: Palette.navy
    ]

    drawText("ESPACIOS DESTACADOS", in: CGRect(x: right.minX, y: right.maxY - 16, width: right.width, height: 12), attributes: smallLabelAttrs)
    drawText("Referencias que ayudan a situar el proyecto", in: CGRect(x: right.minX, y: right.maxY - 76, width: right.width, height: 48), attributes: rightTitleAttrs)

    let idealItems = [
        "FC Barcelona · entorno corporativo y técnico",
        "Red Fish y Sea Sea Club · eventos corporativos y celebraciones privadas",
        "Can Marc · bodas y aniversarios",
        "Cap Sa Sal y Bellport · vermuts y tardeos",
        "La Ruïna y Lincoln · nightlife con lectura de pista",
        "BCN en las Alturas · markets con DJ's y música en directo",
        "Venteo Platja d'Aro · energía Costa Brava",
        "Ajuntament de Palamós · acto público y contexto institucional"
    ]

    for (index, item) in idealItems.enumerated() {
        drawBulletListItem(item, rect: CGRect(x: right.minX, y: right.maxY - 110 - CGFloat(index) * 32, width: right.width, height: 28))
    }

    let ctaCard = CGRect(x: right.minX, y: right.minY + 8, width: right.width, height: 122)
    let ctaFill = NSColor(calibratedRed: 232 / 255, green: 240 / 255, blue: 247 / 255, alpha: 1)
    fillRoundedRect(ctaCard, radius: 20, color: ctaFill)
    strokeRoundedRect(ctaCard, radius: 20, color: Palette.slate.withAlphaComponent(0.34), lineWidth: 1.2)

    drawText("Pide propuesta personalizada", in: CGRect(x: ctaCard.minX + 16, y: ctaCard.maxY - 32, width: ctaCard.width - 32, height: 22), attributes: [
        .font: font("Avenir Next Heavy", size: 16),
        .foregroundColor: Palette.navy
    ])
    drawText("Te orientamos según espacio, horario, volumen, estilo musical y tipo de invitados.", in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 58, width: ctaCard.width - 32, height: 32), attributes: [
        .font: font("Avenir Next Medium", size: 9.8),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.8)
    ])

    drawText(phone1 + " / " + phone2, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 32, width: ctaCard.width - 32, height: 16), attributes: [
        .font: font("Avenir Next Demi Bold", size: 10.2),
        .foregroundColor: Palette.navy
    ])
    drawText(email, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 18, width: ctaCard.width - 32, height: 16), attributes: [
        .font: font("Avenir Next Medium", size: 9.8),
        .foregroundColor: Palette.navy
    ])
    drawText(web, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 6, width: ctaCard.width - 32, height: 16), attributes: [
        .font: font("Avenir Next Medium", size: 9.8),
        .foregroundColor: Palette.navy
    ])

}

func renderPDF(to url: URL, draw: (CGContext) -> Void) throws {
    var mediaBox = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "trifold", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF \(url.lastPathComponent)"])
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
    let pxWidth = Int((TrifoldSpec.pageWidthMM / 25.4 * TrifoldSpec.dpi).rounded())
    let pxHeight = Int((TrifoldSpec.pageHeightMM / 25.4 * TrifoldSpec.dpi).rounded())

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
        throw NSError(domain: "trifold", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el bitmap"])
    }

    rep.size = NSSize(width: TrifoldSpec.pageSize.width, height: TrifoldSpec.pageSize.height)

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
        throw NSError(domain: "trifold", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el contexto PNG"])
    }

    ctx.interpolationQuality = .high

    let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    draw(ctx)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "trifold", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo exportar el PNG"])
    }
    try data.write(to: url)
}

func renderCombinedPreviewPDF(to url: URL, outsideImage: NSImage, insideImage: NSImage) throws {
    var mediaBox = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "trifold", code: 5, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF combinado"])
    }

    ctx.beginPDFPage(nil)
    var graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    outsideImage.draw(in: CGRect(origin: .zero, size: TrifoldSpec.pageSize))
    NSGraphicsContext.restoreGraphicsState()
    ctx.endPDFPage()

    ctx.beginPDFPage(nil)
    graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    ctx.saveGState()
    ctx.translateBy(x: TrifoldSpec.pageSize.width, y: TrifoldSpec.pageSize.height)
    ctx.rotate(by: .pi)
    insideImage.draw(in: CGRect(origin: .zero, size: TrifoldSpec.pageSize))
    ctx.restoreGState()
    NSGraphicsContext.restoreGraphicsState()
    ctx.endPDFPage()

    ctx.closePDF()
}

func renderPreviewPDF(to url: URL, outsideImage: NSImage, insideImage: NSImage) throws {
    var mediaBox = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "trifold", code: 6, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF de previews"])
    }

    for image in [outsideImage, insideImage] {
        ctx.beginPDFPage(nil)
        let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        image.draw(in: CGRect(origin: .zero, size: TrifoldSpec.pageSize))
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
    }

    ctx.closePDF()
}

let previewSuffix = outputSlug.isEmpty ? "" : "-\(outputSlug)"
let outsidePDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-outside-print\(previewSuffix).pdf")
let insidePDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-inside-print\(previewSuffix).pdf")
let combinedPDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-print\(previewSuffix).pdf")
let outsidePNG = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-outside-preview\(previewSuffix).png")
let insidePNG = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-inside-preview\(previewSuffix).png")
let previewPDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-preview-pages\(previewSuffix).pdf")

try renderPDF(to: outsidePDF, draw: drawOutside)
try renderPDF(to: insidePDF, draw: drawInside)
try renderPNG(to: outsidePNG, draw: drawOutside)
try renderPNG(to: insidePNG, draw: drawInside)
if let outsidePreview = NSImage(contentsOf: outsidePNG), let insidePreview = NSImage(contentsOf: insidePNG) {
    try renderCombinedPreviewPDF(to: combinedPDF, outsideImage: outsidePreview, insideImage: insidePreview)
    try renderPreviewPDF(to: previewPDF, outsideImage: outsidePreview, insideImage: insidePreview)
}

print(outsidePDF.path)
print(insidePDF.path)
print(combinedPDF.path)
print(outsidePNG.path)
print(insidePNG.path)
print(previewPDF.path)
