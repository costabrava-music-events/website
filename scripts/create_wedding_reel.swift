import AVFoundation
import AppKit
import QuartzCore

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root.appendingPathComponent("assets/social/wedding-2026-07-25")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let clips = [
    "WhatsApp Video 2026-07-25 at 18.39.55.mp4",
    "WhatsApp Video 2026-07-25 at 18.36.02.mp4",
    "WhatsApp Video 2026-07-25 at 18.35.48.mp4",
    "WhatsApp Video 2026-07-25 at 20.46.03.mp4"
].map { URL(fileURLWithPath: "/Users/albertbitdj/Downloads/\($0)") }

let durations = [6.0, 5.0, 6.0, 7.0]
let composition = AVMutableComposition()
let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
var cursor = CMTime.zero

for (index, url) in clips.enumerated() {
    let asset = AVURLAsset(url: url)
    let sourceDuration = CMTime(seconds: durations[index], preferredTimescale: 600)
    let range = CMTimeRange(start: .zero, duration: sourceDuration)
    guard let sourceVideo = asset.tracks(withMediaType: .video).first else { fatalError("Missing video: \(url.lastPathComponent)") }
    try videoTrack.insertTimeRange(range, of: sourceVideo, at: cursor)
    if let sourceAudio = asset.tracks(withMediaType: .audio).first {
        try audioTrack.insertTimeRange(range, of: sourceAudio, at: cursor)
    }
    cursor = cursor + sourceDuration
}

let renderSize = CGSize(width: 1080, height: 1920)
let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
let scale = renderSize.width / 478
var instructions: [AVVideoCompositionInstructionProtocol] = []
var instructionStart = CMTime.zero
for duration in durations {
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: instructionStart, duration: CMTime(seconds: duration, preferredTimescale: 600))
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    layerInstruction.setTransform(CGAffineTransform(scaleX: scale, y: scale), at: instructionStart)
    instruction.layerInstructions = [layerInstruction]
    instructions.append(instruction)
    instructionStart = instructionStart + CMTime(seconds: duration, preferredTimescale: 600)
}
videoComposition.instructions = instructions

func textLayer(_ string: String, fontSize: CGFloat, frame: CGRect, opacity: Float = 1) -> CATextLayer {
    let layer = CATextLayer()
    layer.string = string
    layer.font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    layer.fontSize = fontSize
    layer.alignmentMode = .center
    layer.foregroundColor = NSColor.white.cgColor
    layer.shadowColor = NSColor.black.cgColor
    layer.shadowOpacity = 0.7
    layer.shadowRadius = 7
    layer.shadowOffset = CGSize(width: 0, height: -2)
    layer.opacity = opacity
    layer.frame = frame
    layer.contentsScale = 2
    return layer
}

let parentLayer = CALayer()
parentLayer.frame = CGRect(origin: .zero, size: renderSize)
let videoLayer = CALayer()
videoLayer.frame = parentLayer.frame
parentLayer.addSublayer(videoLayer)

let brand = textLayer("COSTA BRAVA MUSIC EVENTS", fontSize: 34, frame: CGRect(x: 54, y: 1770, width: 972, height: 50), opacity: 0.88)
parentLayer.addSublayer(brand)

let closing = textLayer("LIVE MUSIC FOR\nUNFORGETTABLE WEDDINGS", fontSize: 48, frame: CGRect(x: 70, y: 260, width: 940, height: 150))
closing.isWrapped = true
closing.opacity = 0
let closingFade = CABasicAnimation(keyPath: "opacity")
closingFade.fromValue = 0
closingFade.toValue = 1
closingFade.beginTime = AVCoreAnimationBeginTimeAtZero + 21
closingFade.duration = 0.7
closingFade.fillMode = .forwards
closingFade.isRemovedOnCompletion = false
closing.add(closingFade, forKey: "fadeIn")
parentLayer.addSublayer(closing)

let website = textLayer("costabravamusicevents.com", fontSize: 30, frame: CGRect(x: 70, y: 195, width: 940, height: 40))
website.opacity = 0
let websiteFade = CABasicAnimation(keyPath: "opacity")
websiteFade.fromValue = 0
websiteFade.toValue = 0.95
websiteFade.beginTime = AVCoreAnimationBeginTimeAtZero + 21.3
websiteFade.duration = 0.7
websiteFade.fillMode = .forwards
websiteFade.isRemovedOnCompletion = false
website.add(websiteFade, forKey: "fadeIn")
parentLayer.addSublayer(website)

videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

let outputURL = outputDirectory.appendingPathComponent("cbme-wedding-live-music-reel.mp4")
try? FileManager.default.removeItem(at: outputURL)
guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { fatalError("Unable to export") }
exporter.outputURL = outputURL
exporter.outputFileType = .mp4
exporter.videoComposition = videoComposition
exporter.shouldOptimizeForNetworkUse = true
let semaphore = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { semaphore.signal() }
semaphore.wait()
guard exporter.status == .completed else { fatalError(exporter.error?.localizedDescription ?? "Export failed") }

let imageGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: outputURL))
imageGenerator.appliesPreferredTrackTransform = true
let coverImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 18, preferredTimescale: 600), actualTime: nil)
let coverURL = outputDirectory.appendingPathComponent("cbme-wedding-live-music-reel-cover.jpg")
let bitmap = NSBitmapImageRep(cgImage: coverImage)
try bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92])!.write(to: coverURL)

print(outputURL.path)
print(coverURL.path)
