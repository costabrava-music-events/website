#!/usr/bin/env swift
import Foundation
import AVFoundation
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let campaignDir = root.appendingPathComponent("assets/social/live-reel-2026-05-29", isDirectory: true)
let sourceDir = campaignDir.appendingPathComponent("source", isDirectory: true)
let outputURL = campaignDir.appendingPathComponent("contact-sheet.png")
let files = ["video-01.mp4", "video-02.mp4", "video-03.mp4"]
let times: [Double] = [2, 7, 12, 17, 22]
let thumb = CGSize(width: 216, height: 384)
let labelHeight: CGFloat = 42
let padding: CGFloat = 18
let columns = times.count
let rows = files.count
let canvasSize = CGSize(
    width: padding + CGFloat(columns) * (thumb.width + padding),
    height: padding + CGFloat(rows) * (thumb.height + labelHeight + padding)
)

func frame(asset: AVAsset, at seconds: Double) throws -> NSImage {
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = thumb
    let image = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: nil)
    return NSImage(cgImage: image, size: thumb)
}

func drawCover(_ image: NSImage, in rect: CGRect) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
    let source = CGSize(width: cgImage.width, height: cgImage.height)
    let sourceAspect = source.width / source.height
    let targetAspect = rect.width / rect.height
    var draw = rect
    if sourceAspect > targetAspect {
        let width = rect.height * sourceAspect
        draw.origin.x = rect.midX - width / 2
        draw.size.width = width
    } else {
        let height = rect.width / sourceAspect
        draw.origin.y = rect.midY - height / 2
        draw.size.height = height
    }
    NSGraphicsContext.current?.cgContext.draw(cgImage, in: draw)
}

let canvas = NSImage(size: canvasSize)
canvas.lockFocus()
NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1).setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: canvasSize)).fill()

let labelAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
    .foregroundColor: NSColor.white
]
let timeAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.78, blue: 0.42, alpha: 1)
]

for (row, file) in files.enumerated() {
    let asset = AVURLAsset(url: sourceDir.appendingPathComponent(file))
    let y = canvasSize.height - padding - CGFloat(row + 1) * (thumb.height + labelHeight + padding)
    file.draw(at: CGPoint(x: padding, y: y + thumb.height + 10), withAttributes: labelAttrs)
    for (column, second) in times.enumerated() {
        let x = padding + CGFloat(column) * (thumb.width + padding)
        let rect = CGRect(x: x, y: y, width: thumb.width, height: thumb.height)
        do {
            let image = try frame(asset: asset, at: second)
            drawCover(image, in: rect)
        } catch {
            NSColor.darkGray.setFill()
            NSBezierPath(rect: rect).fill()
        }
        "\(Int(second))s".draw(at: CGPoint(x: x + 10, y: y + 10), withAttributes: timeAttrs)
    }
}

canvas.unlockFocus()
guard let data = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "contact.sheet", code: 1)
}
try png.write(to: outputURL)
print(outputURL.path)
