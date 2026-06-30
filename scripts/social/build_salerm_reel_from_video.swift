#!/usr/bin/env swift
import Foundation
import AVFoundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputURL = root.appendingPathComponent("assets/social/salerm-vmw-2026-05-25/source/video-02.mp4")
let outDir = root.appendingPathComponent("assets/social/salerm-vmw-2026-05-25", isDirectory: true)
let outputURL = outDir.appendingPathComponent("salerm-reel-v2.mov")

let clips: [(start: Double, duration: Double)] = [
    (7.6, 2.8),
    (13.4, 3.2),
    (19.4, 3.2),
    (35.8, 3.0),
    (51.0, 3.2),
    (59.5, 4.2),
]

func export() async throws {
    try? FileManager.default.removeItem(at: outputURL)
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    let asset = AVURLAsset(url: inputURL)
    let composition = AVMutableComposition()
    guard let sourceVideo = try await asset.loadTracks(withMediaType: .video).first else {
        throw NSError(domain: "salerm.reel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sin track de video"])
    }
    let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first
    guard let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        throw NSError(domain: "salerm.reel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear track de video"])
    }
    let compAudio = sourceAudio.flatMap { _ in composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) }
    let transform = try await sourceVideo.load(.preferredTransform)
    compVideo.preferredTransform = transform

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

    guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
        throw NSError(domain: "salerm.reel", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear exporter"])
    }
    exporter.outputURL = outputURL
    exporter.outputFileType = .mov
    exporter.shouldOptimizeForNetworkUse = true
    try await exporter.export(to: outputURL, as: .mov)
    print(outputURL.path)
}

Task {
    do {
        try await export()
        exit(0)
    } catch {
        fputs("ERROR: \(error)\n", stderr)
        exit(1)
    }
}
RunLoop.main.run()
