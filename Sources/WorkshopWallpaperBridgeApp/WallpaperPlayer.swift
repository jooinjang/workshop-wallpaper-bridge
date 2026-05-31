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
            return RestrictedWebWallpaperView(
                url: url,
                readAccessURL: URL(filePath: asset.projectDirectory),
                frame: frame
            )
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
private final class RestrictedWebWallpaperView: NSView, WKNavigationDelegate {
    private let webView: WKWebView
    private let url: URL
    private let readAccessURL: URL

    init(url: URL, readAccessURL: URL, frame: CGRect) {
        self.url = url
        self.readAccessURL = readAccessURL
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: frame, configuration: configuration)
        super.init(frame: frame)
        webView.navigationDelegate = self
        addSubview(webView)
        installRemoteBlockerAndLoad()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        webView.frame = bounds
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        let targetURL = navigationAction.request.url
        decisionHandler(targetURL?.isFileURL == true ? .allow : .cancel)
    }

    private func installRemoteBlockerAndLoad() {
        let rules = #"""
        [{"trigger":{"url-filter":"^https?://.*"},"action":{"type":"block"}}]
        """#
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "dev.3xhaust.WorkshopWallpaperBridge.BlockRemote",
            encodedContentRuleList: rules
        ) { [weak self] ruleList, _ in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                if let ruleList {
                    self.webView.configuration.userContentController.add(ruleList)
                }
                self.webView.loadFileURL(self.url, allowingReadAccessTo: self.readAccessURL)
            }
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
