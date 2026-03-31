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
let logoURL = cwd.appendingPathComponent("assets/img/logo-transparente.png")
let eventPhotoURL = cwd.appendingPathComponent("assets/img/stock/pexels-dj-vinyl.jpg")

try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let logo = NSImage(contentsOf: logoURL) else {
    fputs("No se ha podido cargar el logo en \(logoURL.path)\n", stderr)
    exit(1)
}

let eventPhoto = NSImage(contentsOf: eventPhotoURL)

let brand = "Costa Brava Music Events"
let title = "Eventos privados\ndeep-house & chillout"
let subtitle = "Música, sonido e iluminación para villas, terrazas, jardines y celebraciones con personalidad."
let contactCopy = "Cuéntanos la fecha, el espacio y el tipo de público. Te preparamos una propuesta clara, elegante y adaptada al ambiente que buscas."
let web = "www.costabravamusicevents.com"
let instagram = "@costabrava_music_events"
let email = "info@costabravamusicevents.com"
let phone1 = "619 840 602"
let phone2 = "687 962 905"
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
        .font: font("Avenir Next Medium", size: 9.8),
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
        .font: font("Avenir Next Demi Bold", size: 11.4),
        .foregroundColor: NSColor.white
    ])

    drawText(text, in: CGRect(x: rect.minX + 46, y: rect.minY + 8, width: rect.width - 58, height: rect.height - 42), attributes: [
        .font: font("Avenir Next Medium", size: 8.9),
        .foregroundColor: NSColor.white.withAlphaComponent(0.84),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.4)
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

    fillRoundedRect(CGRect(x: left.minX, y: left.minY, width: left.width, height: left.height), radius: 24, color: Palette.paper)
    fillRoundedRect(CGRect(x: middle.minX, y: middle.minY, width: middle.width, height: middle.height), radius: 24, color: NSColor.white.withAlphaComponent(0.06))
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
        .font: font("Avenir Next Heavy", size: 15.6),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.0, minimumLineHeight: 17)
    ]
    let middleBodyAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Medium", size: 10.1),
        .foregroundColor: NSColor.white.withAlphaComponent(0.82),
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ]

    drawText("ATMÓSFERA", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 10, width: middleContent.width, height: 12), attributes: middleLabelAttrs)
    drawText("Groove elegante, energía medida", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 78, width: middleContent.width, height: 52), attributes: middleTitleAttrs)
    drawText("No pinchamos en piloto automático. Diseñamos la energía del evento para que todo fluya: bienvenida suave, sunset elegante, groove cálido y una subida final con intención.", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 170, width: middleContent.width, height: 84), attributes: middleBodyAttrs)

    drawCompactPill("Villas privadas", origin: CGPoint(x: middleContent.minX, y: middleContent.maxY - 198), dark: true)
    drawCompactPill("Rooftops", origin: CGPoint(x: middleContent.minX + 74, y: middleContent.maxY - 198), dark: true)
    drawCompactPill("Jardines", origin: CGPoint(x: middleContent.minX + 132, y: middleContent.maxY - 198), dark: true)
    drawCompactPill("Beach houses", origin: CGPoint(x: middleContent.minX, y: middleContent.maxY - 224), dark: true)
    drawCompactPill("Celebraciones con estilo", origin: CGPoint(x: middleContent.minX + 72, y: middleContent.maxY - 224), dark: true)
    drawCompactPill("Private sessions", origin: CGPoint(x: middleContent.minX, y: middleContent.maxY - 250), dark: true)
    drawCompactPill("Costa Brava", origin: CGPoint(x: middleContent.minX + 86, y: middleContent.maxY - 250), dark: true)

    let quoteRect = CGRect(x: middleContent.minX, y: middleContent.minY, width: middleContent.width, height: 94)
    fillRoundedRect(quoteRect, radius: 18, color: NSColor.white.withAlphaComponent(0.07))
    drawText("Una selección musical bien pensada cambia por completo cómo se siente un evento privado.", in: quoteRect.insetBy(dx: 16, dy: 14), attributes: [
        .font: font("Avenir Next Demi Bold", size: 10.9),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.8)
    ])

    let rightLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.6),
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

    let logoPlateRect = CGRect(
        x: right.midX - 114,
        y: rightContent.maxY - 182,
        width: 228,
        height: 166
    )
    fillRoundedRect(logoPlateRect, radius: 34, color: NSColor.white.withAlphaComponent(0.08))

    let logoSize: CGFloat = 228
    let logoRect = CGRect(
        x: logoPlateRect.midX - logoSize / 2,
        y: logoPlateRect.midY - logoSize / 2 + 4,
        width: logoSize,
        height: logoSize
    )
    logo.draw(in: logoRect)

    drawText(brand.uppercased(), in: CGRect(x: rightContent.minX, y: rightContent.maxY - 214, width: rightContent.width, height: 12), attributes: rightLabelAttrs)
    drawText(title, in: CGRect(x: rightContent.minX, y: rightContent.maxY - 344, width: rightContent.width, height: 118), attributes: rightTitleAttrs)
    drawText(subtitle, in: CGRect(x: rightContent.minX, y: rightContent.maxY - 420, width: rightContent.width, height: 78), attributes: rightBodyAttrs)

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
    fillRoundedRect(middlePanelRect, radius: 24, color: Palette.night)
    drawRoundedGradient(
        in: middlePanelRect,
        radius: 24,
        colors: [Palette.cyan.withAlphaComponent(0.18), .clear],
        angle: -90
    )

    let smallLabelAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Demi Bold", size: 8.4),
        .foregroundColor: Palette.slate,
        .kern: 1.6
    ]
    let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 17.4),
        .foregroundColor: Palette.navy
    ]

    drawText("QUÉ HACEMOS", in: CGRect(x: left.minX, y: left.maxY - 16, width: left.width, height: 12), attributes: smallLabelAttrs)
    drawText("Diseñamos la música y el ambiente del evento", in: CGRect(x: left.minX, y: left.maxY - 78, width: left.width, height: 56), attributes: sectionTitleAttrs)
    drawText("Trabajamos eventos privados donde el sonido debe elevar el espacio sin robarle elegancia. Seleccionamos repertorio, niveles, transiciones y atmósfera según el tipo de público y el momento del evento.", in: CGRect(x: left.minX, y: left.maxY - 154, width: left.width, height: 80), attributes: [
        .font: font("Avenir Next Medium", size: 10.1),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2)
    ])

    drawBulletRow(symbol: "01", title: "Selección musical personalizada", text: "Nada de sets genéricos. Adaptamos el recorrido musical al tono del evento y al perfil de invitados.", rect: CGRect(x: left.minX, y: left.maxY - 236, width: left.width, height: 66))
    drawBulletRow(symbol: "02", title: "Sonido premium", text: "Equipos ajustados al espacio para que todo suene limpio, elegante y sin excesos.", rect: CGRect(x: left.minX, y: left.maxY - 310, width: left.width, height: 56))
    drawBulletRow(symbol: "03", title: "Iluminación con intención", text: "Luz ambiental y de fiesta pensada para acompañar la arquitectura y el ambiente.", rect: CGRect(x: left.minX, y: left.maxY - 388, width: left.width, height: 56))
    drawBulletRow(symbol: "04", title: "Coordinación integral", text: "Nos coordinamos con venue y proveedores para que tú solo te ocupes de disfrutar.", rect: CGRect(x: left.minX, y: left.maxY - 466, width: left.width, height: 56))

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

    drawText("LA SESIÓN", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 4, width: middleContent.width, height: 12), attributes: darkLabelAttrs)
    drawText("Deep-house y chillout con progresión real", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 78, width: middleContent.width, height: 56), attributes: darkTitleAttrs)
    drawText("Buscamos una energía cuidada, sofisticada y nada estridente. El evento respira mejor cuando la música acompaña cada tramo con naturalidad.", in: CGRect(x: middleContent.minX, y: middleContent.maxY - 146, width: middleContent.width, height: 62), attributes: darkBodyAttrs)

    let stageCardWidth = middleContent.width
    let stage1 = CGRect(x: middleContent.minX, y: middleContent.maxY - 226, width: stageCardWidth, height: 70)
    let stage2 = CGRect(x: middleContent.minX, y: middleContent.maxY - 304, width: stageCardWidth, height: 70)
    let stage3 = CGRect(x: middleContent.minX, y: middleContent.maxY - 382, width: stageCardWidth, height: 70)

    drawStageCard(symbol: "A", title: "Warm-up", text: "Recepción, cóctel o primer tramo con textura elegante y tempo relajado.", rect: stage1)
    drawStageCard(symbol: "B", title: "Sunset groove", text: "Deep-house cálido y sofisticado para acompañar el momento alto.", rect: stage2)
    drawStageCard(symbol: "C", title: "Late session", text: "Subida controlada para seguir disfrutando, bailar y cerrar con estilo.", rect: stage3)

    let quote = CGRect(x: middleContent.minX, y: middleContent.minY + 6, width: middleContent.width, height: 90)
    fillRoundedRect(quote, radius: 18, color: NSColor.white.withAlphaComponent(0.07))
    drawText("El objetivo no es sonar fuerte. Es hacer que el espacio, la gente y el momento encajen.", in: quote.insetBy(dx: 16, dy: 14), attributes: [
        .font: font("Avenir Next Demi Bold", size: 12.2),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 2.4)
    ])

    let rightTitleAttrs: [NSAttributedString.Key: Any] = [
        .font: font("Avenir Next Heavy", size: 16.2),
        .foregroundColor: Palette.navy
    ]

    drawText("IDEAL PARA", in: CGRect(x: right.minX, y: right.maxY - 16, width: right.width, height: 12), attributes: smallLabelAttrs)
    drawText("Espacios y eventos con estilo", in: CGRect(x: right.minX, y: right.maxY - 72, width: right.width, height: 44), attributes: rightTitleAttrs)

    let idealItems = [
        "Fiestas privadas",
        "Villas, jardines y terrazas con personalidad",
        "Pool parties elegantes y sunset sessions",
        "Aniversarios, cumpleaños especiales e inauguraciones",
        "Eventos donde el ambiente importa tanto como la música"
    ]

    for (index, item) in idealItems.enumerated() {
        drawBulletListItem(item, rect: CGRect(x: right.minX, y: right.maxY - 114 - CGFloat(index) * 30, width: right.width, height: 24))
    }

    let photoRect = CGRect(x: right.minX, y: right.minY + 168, width: right.width, height: 110)
    if let eventPhoto {
        drawImageAspectFill(eventPhoto, in: photoRect, cornerRadius: 18)
        strokeRoundedRect(photoRect, radius: 18, color: Palette.line, lineWidth: 0.8)
    }

    let ctaCard = CGRect(x: right.minX, y: right.minY + 8, width: right.width, height: 132)
    let ctaFill = NSColor(calibratedRed: 232 / 255, green: 240 / 255, blue: 247 / 255, alpha: 1)
    fillRoundedRect(ctaCard, radius: 20, color: ctaFill)
    strokeRoundedRect(ctaCard, radius: 20, color: Palette.slate.withAlphaComponent(0.34), lineWidth: 1.2)

    drawText("Pide propuesta personalizada", in: CGRect(x: ctaCard.minX + 16, y: ctaCard.maxY - 34, width: ctaCard.width - 32, height: 22), attributes: [
        .font: font("Avenir Next Heavy", size: 16),
        .foregroundColor: Palette.navy
    ])
    drawText("Te orientamos según espacio, horario, volumen, estilo musical y tipo de invitados.", in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 66, width: ctaCard.width - 32, height: 30), attributes: [
        .font: font("Avenir Next Medium", size: 9.8),
        .foregroundColor: Palette.slate,
        .paragraphStyle: paragraph(alignment: .left, lineSpacing: 1.8)
    ])

    drawText(phone1 + " / " + phone2, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 38, width: ctaCard.width - 32, height: 16), attributes: [
        .font: font("Avenir Next Demi Bold", size: 10.2),
        .foregroundColor: Palette.navy
    ])
    drawText(email, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 22, width: ctaCard.width - 32, height: 16), attributes: [
        .font: font("Avenir Next Medium", size: 9.8),
        .foregroundColor: Palette.navy
    ])
    drawText(web, in: CGRect(x: ctaCard.minX + 16, y: ctaCard.minY + 8, width: ctaCard.width - 32, height: 16), attributes: [
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

func renderCombinedPDF(to url: URL) throws {
    var mediaBox = CGRect(origin: .zero, size: TrifoldSpec.pageSize)
    guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "trifold", code: 5, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el PDF combinado"])
    }

    for drawer in [drawOutside, drawInside] {
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

let outsidePDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-outside-print.pdf")
let insidePDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-inside-print.pdf")
let combinedPDF = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-print.pdf")
let outsidePNG = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-outside-preview.png")
let insidePNG = outputDir.appendingPathComponent("cbme-trifold-private-events-deep-house-chillout-inside-preview.png")

try renderPDF(to: outsidePDF, draw: drawOutside)
try renderPDF(to: insidePDF, draw: drawInside)
try renderCombinedPDF(to: combinedPDF)
try renderPNG(to: outsidePNG, draw: drawOutside)
try renderPNG(to: insidePNG, draw: drawInside)

print(outsidePDF.path)
print(insidePDF.path)
print(combinedPDF.path)
print(outsidePNG.path)
print(insidePNG.path)
