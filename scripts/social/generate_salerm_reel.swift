#!/usr/bin/env swift
import Foundation
import AVFoundation
import AppKit

struct Segment {
    let imageName: String
    let start: Double
    let duration: Double
    let kicker: String
    let title: String
    let subtitle: String
    let alignment: NSTextAlignment
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceDir = root.appendingPathComponent("assets/social/salerm-vmw-2026-05-25/source", isDirectory: true)
let outDir = root.appendingPathComponent("assets/social/salerm-vmw-2026-05-25", isDirectory: true)
let outputURL = outDir.appendingPathComponent("salerm-reel-v1.mov")
let coverURL = outDir.appendingPathComponent("salerm-reel-cover.png")

let size = CGSize(width: 1080, height: 1920)
let fps = 30
let totalDuration = 12.0
let segments = [
    Segment(
        imageName: "image-02.jpeg",
        start: 0.0,
        duration: 4.0,
        kicker: "SALERM VMW COSMETICS",
        title: "Cada evento empieza mucho antes de que llegue la gente",
        subtitle: "Producción de evento cuidada desde el montaje.",
        alignment: .left
    ),
    Segment(
        imageName: "image-03.jpeg",
        start: 4.0,
        duration: 4.0,
        kicker: "PRODUCCIÓN · COORDINACIÓN · EJECUCIÓN",
        title: "Todo tiene que encajar antes de que empiece el evento",
        subtitle: "Espacio, servicio y ritmo visual en una misma ejecución.",
        alignment: .left
    ),
    Segment(
        imageName: "image-01.jpeg",
        start: 8.0,
        duration: 4.0,
        kicker: "EVENTO CORPORATIVO",
        title: "Así fue el evento de SALERM VMW COSMETICS",
        subtitle: "Un montaje pensado para que la experiencia fluya de principio a final.",
        alignment: .left
    ),
]

func loadImage(named name: String) -> NSImage {
    let url = sourceDir.appendingPathComponent(name)
    guard let image = NSImage(contentsOf: url) else {
        fatalError("No se pudo cargar \(url.path)")
    }
    return image
}

let images = Dictionary(uniqueKeysWithValues: Set(segments.map(\.imageName)).map { ($0, loadImage(named: $0)) })

func paragraph(_ align: NSTextAlignment, lineHeight: CGFloat = 1.08) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineBreakMode = .byWordWrapping
    style.minimumLineHeight = 0
    style.maximumLineHeight = 0
    style.lineSpacing = 0
    return style
}

func alphaForSegment(localTime: Double, duration: Double) -> CGFloat {
    let fade = min(0.45, duration * 0.18)
    if localTime < fade { return CGFloat(localTime / fade) }
    if localTime > duration - fade { return CGFloat((duration - localTime) / fade) }
    return 1
}

func drawImage(_ image: NSImage, in rect: CGRect, progress: CGFloat) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    let canvasAspect = rect.width / rect.height
    let imageAspect = imageSize.width / imageSize.height
    var drawRect = rect
    if imageAspect > canvasAspect {
        let width = rect.height * imageAspect
        drawRect.origin.x = rect.midX - width / 2
        drawRect.size.width = width
    } else {
        let height = rect.width / imageAspect
        drawRect.origin.y = rect.midY - height / 2
        drawRect.size.height = height
    }

    let scale = 1.03 + (0.05 * progress)
    let dx = (progress - 0.5) * 42
    let dy = (0.5 - progress) * 26
    let scaled = CGRect(
        x: drawRect.midX - (drawRect.width * scale) / 2 + dx,
        y: drawRect.midY - (drawRect.height * scale) / 2 + dy,
        width: drawRect.width * scale,
        height: drawRect.height * scale
    )
    NSGraphicsContext.current?.cgContext.draw(cgImage, in: scaled)
}

func drawGradient(in rect: CGRect) {
    let ctx = NSGraphicsContext.current!.cgContext
    let colors = [NSColor(calibratedWhite: 0, alpha: 0.02).cgColor,
                  NSColor(calibratedWhite: 0, alpha: 0.18).cgColor,
                  NSColor(calibratedWhite: 0, alpha: 0.82).cgColor] as CFArray
    let locations: [CGFloat] = [0.0, 0.45, 1.0]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
}

func drawText(for segment: Segment, alpha: CGFloat, in rect: CGRect) {
    let textAlpha = max(0, min(1, alpha))
    let kickerAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 36, weight: .semibold),
        .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.84, blue: 0.43, alpha: textAlpha),
        .paragraphStyle: paragraph(segment.alignment)
    ]
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 86, weight: .bold),
        .foregroundColor: NSColor(white: 1, alpha: textAlpha),
        .paragraphStyle: paragraph(segment.alignment)
    ]
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 44, weight: .regular),
        .foregroundColor: NSColor(calibratedWhite: 0.93, alpha: textAlpha),
        .paragraphStyle: paragraph(segment.alignment)
    ]

    let maxWidth = rect.width - 140
    let kickerRect = CGRect(x: 70, y: 420, width: maxWidth, height: 60)
    let titleRect = CGRect(x: 70, y: 185, width: maxWidth, height: 220)
    let subtitleRect = CGRect(x: 70, y: 90, width: maxWidth, height: 90)
    segment.kicker.draw(in: kickerRect, withAttributes: kickerAttributes)
    segment.title.draw(in: titleRect, withAttributes: titleAttributes)
    segment.subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
}

func makeFrame(at time: Double) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor.black.setFill()
    NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
    let rect = CGRect(origin: .zero, size: size)

    for segment in segments {
        guard time >= segment.start && time < segment.start + segment.duration else { continue }
        let local = time - segment.start
        let progress = CGFloat(local / segment.duration)
        let alpha = alphaForSegment(localTime: local, duration: segment.duration)
        if let source = images[segment.imageName] {
            drawImage(source, in: rect, progress: progress)
        }
        drawGradient(in: rect)
        drawText(for: segment, alpha: alpha, in: rect)
    }

    image.unlockFocus()
    return image
}

func pixelBufferPoolAdaptor(for writerInput: AVAssetWriterInput, size: CGSize) -> AVAssetWriterInputPixelBufferAdaptor {
    let attributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: Int(size.width),
        kCVPixelBufferHeightKey as String: Int(size.height)
    ]
    return AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: attributes)
}

func pixelBuffer(from image: NSImage, size: CGSize) -> CVPixelBuffer {
    var maybeBuffer: CVPixelBuffer?
    let attrs: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferWidthKey as String: Int(size.width),
        kCVPixelBufferHeightKey as String: Int(size.height),
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)
    ]
    CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs as CFDictionary, &maybeBuffer)
    guard let buffer = maybeBuffer else { fatalError("No se pudo crear pixel buffer") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let ctx = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    ctx.clear(CGRect(origin: .zero, size: size))
    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))
    }
    NSGraphicsContext.restoreGraphicsState()
    CVPixelBufferUnlockBaseAddress(buffer, [])
    return buffer
}

try? FileManager.default.removeItem(at: outputURL)
try? FileManager.default.removeItem(at: coverURL)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.jpeg,
    AVVideoWidthKey: Int(size.width),
    AVVideoHeightKey: Int(size.height),
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 7_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let adaptor = pixelBufferPoolAdaptor(for: input, size: size)
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let queue = DispatchQueue(label: "salerm.reel.writer")
let frameCount = Int(totalDuration * Double(fps))
var currentFrame = 0
let semaphore = DispatchSemaphore(value: 0)
var finishError: Error?

input.requestMediaDataWhenReady(on: queue) {
    while input.isReadyForMoreMediaData && currentFrame < frameCount {
        let time = Double(currentFrame) / Double(fps)
        let frameImage = makeFrame(at: time)
        let buffer = pixelBuffer(from: frameImage, size: size)
        let presentationTime = CMTime(value: CMTimeValue(currentFrame), timescale: CMTimeScale(fps))
        adaptor.append(buffer, withPresentationTime: presentationTime)
        currentFrame += 1
    }
    if currentFrame >= frameCount {
        input.markAsFinished()
        writer.finishWriting {
            finishError = writer.error
            semaphore.signal()
        }
    }
}

_ = semaphore.wait(timeout: .now() + 120)
if let finishError {
    throw finishError
}
guard writer.status == .completed else {
    throw writer.error ?? NSError(domain: "salerm.reel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Writer no completado: \(writer.status.rawValue)"])
}

let cover = makeFrame(at: 10.5)
if let tiff = cover.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try png.write(to: coverURL)
}

print(outputURL.path)
print(coverURL.path)
