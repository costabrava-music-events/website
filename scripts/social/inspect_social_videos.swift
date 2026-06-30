#!/usr/bin/env swift
import Foundation
import AVFoundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let files = CommandLine.arguments.dropFirst().map { root.appendingPathComponent($0) }

func describe(_ url: URL) async throws {
    let asset = AVURLAsset(url: url)
    let duration = try await asset.load(.duration).seconds
    let video = try await asset.loadTracks(withMediaType: .video).first
    let audio = try await asset.loadTracks(withMediaType: .audio).first
    let naturalSize = try await video?.load(.naturalSize) ?? .zero
    let transform = try await video?.load(.preferredTransform) ?? .identity
    let transformed = naturalSize.applying(transform)
    let size = CGSize(width: abs(transformed.width), height: abs(transformed.height))
    print("\(url.path)")
    print("  duration: \(String(format: "%.2f", duration))s")
    print("  display: \(Int(size.width))x\(Int(size.height))")
    print("  audio: \(audio == nil ? "no" : "yes")")
}

Task {
    do {
        for file in files {
            try await describe(file)
        }
        exit(0)
    } catch {
        fputs("ERROR: \(error)\n", stderr)
        exit(1)
    }
}

RunLoop.main.run()
