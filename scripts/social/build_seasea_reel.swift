#!/usr/bin/env swift
import Foundation
import AVFoundation
import AppKit

struct Clip {
    let start: Double
    let duration: Double
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let campaignDir = root.appendingPathComponent("assets/social/live-reel-2026-05-29", isDirectory: true)
let sourceURL = campaignDir.appendingPathComponent("source/video-03.mp4")
let reelURL = campaignDir.appendingPathComponent("seasea-reel-2026-05-29-v2.mp4")
let coverURL = campaignDir.appendingPathComponent("seasea-reel-cover-v2.png")

let clips = [
    Clip(start: 2.4, duration: 1.8),
    Clip(start: 4.0, duration: 1.4),
    Clip(start: 5.8, duration: 1.5),
    Clip(start: 10.0, duration: 1.5),
    Clip(start: 12.5, duration: 1.6),
    Clip(start: 17.2, duration: 1.7),
    Clip(start: 19.4, duration: 1.5),
    Clip(start: 22.0, duration: 1.6),
]

func exportReel() async throws {
    try? FileManager.default.removeItem(at: reelURL)
    try FileManager.default.createDirectory(at: campaignDir, withIntermediateDirectories: true)

    let asset = AVURLAsset(url: sourceURL)
    guard let sourceVideo = try await asset.loadTracks(withMediaType: .video).first else {
        throw NSError(domain: "seasea.reel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sin track de video"])
    }
    let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first
    let transform = try await sourceVideo.load(.preferredTransform)

    let composition = AVMutableComposition()
    guard let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        throw NSError(domain: "seasea.reel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear track de video"])
    }
    compVideo.preferredTransform = transform
    let compAudio = sourceAudio.flatMap { _ in composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) }

    var cursor = CMTime.zero
    for clip in clips {
        let start = CMTime(seconds: clip.start, preferredTimescale: 600)
        let duration = CMTime(seconds: clip.duration, preferredTimescale: 600)
        let range = CMTimeRange(start: start, duration: duration)
        try compVideo.insertTimeRange(range, of: sourceVideo, at: cursor)
        if let sourceAudio, let compAudio {
            try compAudio.insertTimeRange(range, of: sourceAudio, at: cursor)
        }
        cursor = cursor + duration
    }

    guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
        throw NSError(domain: "seasea.reel", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear exporter"])
    }
    exporter.outputURL = reelURL
    exporter.outputFileType = .mp4
    exporter.shouldOptimizeForNetworkUse = true
    try await exporter.export(to: reelURL, as: .mp4)
}

func drawCoverImage(_ frame: NSImage, output: URL) throws {
    let size = CGSize(width: 1080, height: 1920)
    let image = NSImage(size: size)
    image.lockFocus()

    NSColor.black.setFill()
    NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

    if let cg = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        let source = CGSize(width: cg.width, height: cg.height)
        let scale = max(size.width / source.width, size.height / source.height)
        let drawSize = CGSize(width: source.width * scale, height: source.height * scale)
        let drawRect = CGRect(
            x: (size.width - drawSize.width) / 2,
            y: (size.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        NSGraphicsContext.current?.cgContext.draw(cg, in: drawRect)
    }

    let ctx = NSGraphicsContext.current!.cgContext
    let colors = [
        NSColor(calibratedWhite: 0, alpha: 0.06).cgColor,
        NSColor(calibratedWhite: 0, alpha: 0.18).cgColor,
        NSColor(calibratedWhite: 0, alpha: 0.82).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 0.45, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 540, y: 1920), end: CGPoint(x: 540, y: 0), options: [])

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    paragraph.lineBreakMode = .byWordWrapping

    let kickerAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 38, weight: .semibold),
        .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.78, blue: 0.42, alpha: 1),
        .paragraphStyle: paragraph
    ]
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 92, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 42, weight: .regular),
        .foregroundColor: NSColor(calibratedWhite: 0.94, alpha: 1),
        .paragraphStyle: paragraph
    ]

    "SEA SEA CLUB".draw(in: CGRect(x: 70, y: 410, width: 940, height: 58), withAttributes: kickerAttrs)
    "Sonido listo frente al mar".draw(in: CGRect(x: 70, y: 190, width: 940, height: 215), withAttributes: titleAttrs)
    "@costabrava_music_events".draw(in: CGRect(x: 70, y: 112, width: 940, height: 58), withAttributes: subtitleAttrs)

    image.unlockFocus()
    guard let data = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: data),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "seasea.cover", code: 4)
    }
    try png.write(to: output)
}

func exportCover() throws {
    try? FileManager.default.removeItem(at: coverURL)
    let asset = AVURLAsset(url: sourceURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    let cg = try generator.copyCGImage(at: CMTime(seconds: 12.8, preferredTimescale: 600), actualTime: nil)
    let frame = NSImage(cgImage: cg, size: .zero)
    try drawCoverImage(frame, output: coverURL)
}

Task {
    do {
        try await exportReel()
        try exportCover()
        print(reelURL.path)
        print(coverURL.path)
        exit(0)
    } catch {
        fputs("ERROR: \(error)\n", stderr)
        exit(1)
    }
}

RunLoop.main.run()
