import AppKit
import CoreGraphics
import Foundation

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outputURL = cwd.appendingPathComponent("assets/img/abstract-venue-card.png")

let width = 1600
let height = 1000

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("No se pudo crear el bitmap\n", stderr)
    exit(1)
}

guard let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
    fputs("No se pudo crear el contexto gráfico\n", stderr)
    exit(1)
}

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

func roundRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fill(_ rect: CGRect, _ cgColor: CGColor) {
    ctx.setFillColor(cgColor)
    ctx.fill(rect)
}

func stroke(_ rect: CGRect, _ cgColor: CGColor, width: CGFloat) {
    ctx.setStrokeColor(cgColor)
    ctx.setLineWidth(width)
    ctx.stroke(rect)
}

func drawGlow(center: CGPoint, radius: CGFloat, inner: CGColor, outer: CGColor) {
    let colors = [inner, outer] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
}

func line(_ from: CGPoint, _ to: CGPoint, color: CGColor, width: CGFloat, alpha: CGFloat = 1) {
    ctx.saveGState()
    ctx.setStrokeColor(color.copy(alpha: alpha) ?? color)
    ctx.setLineWidth(width)
    ctx.move(to: from)
    ctx.addLine(to: to)
    ctx.strokePath()
    ctx.restoreGState()
}

func roundedBand(_ rect: CGRect, color: CGColor, alpha: CGFloat, radius: CGFloat) {
    fill(rect, color.copy(alpha: alpha) ?? color)
    let path = roundRect(rect, radius: radius)
    ctx.addPath(path)
    ctx.setStrokeColor(color.copy(alpha: min(0.18, alpha)) ?? color)
    ctx.setLineWidth(1)
    ctx.strokePath()
}

ctx.setFillColor(color(6, 18, 36))
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

let topGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(7, 20, 39, 1),
        color(9, 31, 63, 1),
        color(17, 48, 84, 1)
    ] as CFArray,
    locations: [0, 0.58, 1]
)
if let topGradient {
    ctx.drawLinearGradient(topGradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [])
}

drawGlow(center: CGPoint(x: 240, y: 790), radius: 260, inner: color(255, 180, 85, 0.40), outer: color(255, 180, 85, 0.0))
drawGlow(center: CGPoint(x: 1260, y: 230), radius: 300, inner: color(245, 92, 128, 0.34), outer: color(245, 92, 128, 0.0))
drawGlow(center: CGPoint(x: 1180, y: 760), radius: 240, inner: color(35, 211, 238, 0.22), outer: color(35, 211, 238, 0.0))
drawGlow(center: CGPoint(x: 560, y: 290), radius: 210, inner: color(254, 214, 118, 0.16), outer: color(254, 214, 118, 0.0))

ctx.saveGState()
ctx.setAlpha(0.16)
for i in stride(from: 0, through: width, by: 110) {
    line(CGPoint(x: CGFloat(i), y: 0), CGPoint(x: CGFloat(i) + 160, y: CGFloat(height)), color: color(255, 255, 255), width: 1)
}
ctx.restoreGState()

ctx.saveGState()
ctx.setAlpha(0.12)
for i in stride(from: 0, through: height, by: 120) {
    line(CGPoint(x: 0, y: CGFloat(i)), CGPoint(x: CGFloat(width), y: CGFloat(i) + 40), color: color(255, 255, 255), width: 0.8)
}
ctx.restoreGState()

let bands: [(CGRect, CGColor, CGFloat, CGFloat)] = [
    (CGRect(x: 180, y: 690, width: 520, height: 120), color(255, 164, 52), 0.18, 30),
    (CGRect(x: 760, y: 640, width: 420, height: 150), color(35, 211, 238), 0.14, 34),
    (CGRect(x: 980, y: 350, width: 340, height: 110), color(245, 92, 128), 0.18, 28),
    (CGRect(x: 260, y: 250, width: 430, height: 135), color(255, 255, 255), 0.08, 34)
]
for (rect, bandColor, alpha, radius) in bands {
    roundedBand(rect, color: bandColor, alpha: alpha, radius: radius)
}

let cards: [(CGRect, CGColor, CGFloat)] = [
    (CGRect(x: 160, y: 620, width: 180, height: 110), color(255, 255, 255), 0.10),
    (CGRect(x: 380, y: 740, width: 210, height: 92), color(255, 255, 255), 0.08),
    (CGRect(x: 660, y: 690, width: 240, height: 98), color(255, 184, 90), 0.14),
    (CGRect(x: 940, y: 780, width: 180, height: 84), color(35, 211, 238), 0.10),
    (CGRect(x: 1120, y: 650, width: 200, height: 110), color(245, 92, 128), 0.10)
]
for (rect, cardColor, alpha) in cards {
    fill(rect, cardColor.copy(alpha: alpha) ?? cardColor)
    stroke(rect, color(255, 255, 255, 0.15), width: 1.1)
}

ctx.saveGState()
ctx.setAlpha(0.28)
for i in stride(from: 80, to: width - 80, by: 80) {
    let heightShift = CGFloat((i % 160) / 2)
    line(CGPoint(x: CGFloat(i), y: 160 + heightShift), CGPoint(x: CGFloat(i) + 120, y: 160 + heightShift + 14), color: color(255, 255, 255), width: 2.0, alpha: 0.10)
}
ctx.restoreGState()

ctx.saveGState()
ctx.setAlpha(0.22)
for i in 0..<14 {
    let x = CGFloat(140 + i * 95)
    let y = CGFloat(120 + (i % 4) * 70)
    ctx.setFillColor(color(255, 255, 255, 0.10))
    ctx.fillEllipse(in: CGRect(x: x, y: y, width: 16, height: 16))
}
ctx.restoreGState()

ctx.saveGState()
ctx.setAlpha(0.15)
line(CGPoint(x: 80, y: 540), CGPoint(x: 1520, y: 580), color: color(255, 255, 255), width: 4, alpha: 0.06)
line(CGPoint(x: 120, y: 480), CGPoint(x: 1480, y: 430), color: color(255, 255, 255), width: 2.5, alpha: 0.08)
ctx.restoreGState()

let imageData = rep.representation(using: .png, properties: [:])
try fm.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try imageData?.write(to: outputURL)
print(outputURL.path)
