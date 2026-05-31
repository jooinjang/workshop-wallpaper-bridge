import AppKit
import AVFoundation
import WebKit
import WorkshopWallpaperCore

@MainActor
final class WallpaperPlayer {
    static let shared = WallpaperPlayer()

    private var windows: [WallpaperWindow] = []

    func play(asset: WallpaperAsset) throws {
        stop()
        guard asset.supportStatus == .playable else {
            throw PlaybackError.notPlayable(asset.supportStatus.rawValue)
        }
        guard let entrypoint = asset.entrypoint else {
            throw PlaybackError.missingEntrypoint
        }
        let url = URL(filePath: entrypoint)
        windows = try NSScreen.screens.map { screen in
            try WallpaperWindow(asset: asset, url: url, frame: screen.frame)
        }
        windows.forEach { $0.show() }
    }

    func stop() {
        windows.forEach { $0.close() }
        windows = []
    }
}

@MainActor
private final class WallpaperWindow {
    private let window: NSWindow

    init(asset: WallpaperAsset, url: URL, frame: CGRect) throws {
        window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.backgroundColor = .black
        window.contentView = try makeContentView(asset: asset, url: url, frame: frame)
    }

    func show() {
        window.orderFrontRegardless()
    }

    func close() {
        window.close()
    }

    private func makeContentView(asset: WallpaperAsset, url: URL, frame: CGRect) throws -> NSView {
        switch asset.kind {
        case .video:
            return VideoWallpaperView(url: url, frame: frame)
        case .web:
            let webView = WKWebView(frame: frame)
            webView.loadFileURL(url, allowingReadAccessTo: URL(filePath: asset.projectDirectory))
            return webView
        case .image:
            guard let image = NSImage(contentsOf: url) else {
                throw PlaybackError.invalidImage
            }
            let imageView = NSImageView(frame: frame)
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            return imageView
        case .scene, .unknown:
            throw PlaybackError.notPlayable(asset.kind.rawValue)
        }
    }
}

@MainActor
private final class VideoWallpaperView: NSView {
    private let player: AVQueuePlayer
    private let looper: AVPlayerLooper

    init(url: URL, frame: CGRect) {
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        player = queue
        looper = AVPlayerLooper(player: queue, templateItem: item)
        super.init(frame: frame)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        wantsLayer = true
        layer = playerLayer
        player.actionAtItemEnd = .none
        player.isMuted = true
        player.play()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        layer?.frame = bounds
    }
}

private enum PlaybackError: Error, LocalizedError {
    case missingEntrypoint
    case invalidImage
    case notPlayable(String)

    var errorDescription: String? {
        switch self {
        case .missingEntrypoint:
            return "The selected project has no playable entrypoint."
        case .invalidImage:
            return "The selected image could not be opened."
        case .notPlayable(let reason):
            return "This project is not playable on macOS: \(reason)."
        }
    }
}
