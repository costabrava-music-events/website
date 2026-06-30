#!/usr/bin/env swift
import Foundation
import AVFoundation
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputURL = root.appendingPathComponent(CommandLine.arguments.dropFirst().first ?? "assets/social/live-reel-2026-05-29/source/video-03.mp4")
let outputURL = root.appendingPathComponent(CommandLine.arguments.dropFirst().dropFirst().first ?? "assets/social/live-reel-2026-05-29/timeline.png")
let times = stride(from: 0.5, through: 26.5, by: 1.0).map { $0 }
let thumb = CGSize(width: 180, height: 320)
let labelHeight: CGFloat = 32
let padding: CGFloat = 14
let columns = 9
let rows = Int(ceil(Double(times.count) / Double(columns)))
let canvasSize = CGSize(
    width: padding + CGFloat(columns) * (thumb.width + padding),
    height: padding + CGFloat(rows) * (thumb.height + labelHeight + padding)
)

func drawCover(_ cg: CGImage, in rect: CGRect) {
    let source = CGSize(width: cg.width, height: cg.height)
    let scale = max(rect.width / source.width, rect.height / source.height)
    let size = CGSize(width: source.width * scale, height: source.height * scale)
    let draw = CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height)
    NSGraphicsContext.current?.cgContext.draw(cg, in: draw)
}

let asset = AVURLAsset(url: inputURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = thumb

let image = NSImage(size: canvasSize)
image.lockFocus()
NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1).setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: canvasSize)).fill()

let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.78, blue: 0.42, alpha: 1)
]

for (index, second) in times.enumerated() {
    let row = index / columns
    let column = index % columns
    let x = padding + CGFloat(column) * (thumb.width + padding)
    let y = canvasSize.height - padding - CGFloat(row + 1) * (thumb.height + labelHeight + padding)
    let rect = CGRect(x: x, y: y + labelHeight, width: thumb.width, height: thumb.height)
    do {
        let cg = try generator.copyCGImage(at: CMTime(seconds: second, preferredTimescale: 600), actualTime: nil)
        drawCover(cg, in: rect)
    } catch {
        NSColor.darkGray.setFill()
        NSBezierPath(rect: rect).fill()
    }
    String(format: "%.1fs", second).draw(at: CGPoint(x: x + 8, y: y + 8), withAttributes: attrs)
}

image.unlockFocus()
guard let data = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "timeline", code: 1)
}
try png.write(to: outputURL)
print(outputURL.path)
