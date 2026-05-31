import Foundation

public struct LibraryStore: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public func load() throws -> LibraryManifest {
        let manifestURL = root.appending(path: "library.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return LibraryManifest(generatedAt: Date(), assets: [])
        }
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder.bridge.decode(LibraryManifest.self, from: data)
    }

    public func importAsset(_ asset: WallpaperAsset) throws -> WallpaperAsset {
        try FileManager.default.createDirectory(at: assetsRoot, withIntermediateDirectories: true)
        let directoryName = storageDirectoryName(for: asset.id)
        let target = assetsRoot.appending(path: directoryName)
        let replacement = assetsRoot.appending(path: ".\(directoryName).incoming-\(UUID().uuidString)")
        let backup = assetsRoot.appending(path: ".\(directoryName).previous-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: URL(filePath: asset.projectDirectory), to: replacement)
        try replaceDirectory(target: target, replacement: replacement, backup: backup)
        let imported = rewrite(asset: asset, source: URL(filePath: asset.projectDirectory), target: target)
        var manifest = try load()
        manifest = LibraryManifest(
            generatedAt: Date(),
            assets: (manifest.assets.filter { $0.id != asset.id } + [imported])
                .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        )
        try save(manifest)
        return imported
    }

    public func replaceAsset(_ asset: WallpaperAsset) throws {
        var manifest = try load()
        manifest = LibraryManifest(
            generatedAt: Date(),
            assets: (manifest.assets.filter { $0.id != asset.id } + [asset])
                .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        )
        try save(manifest)
    }

    public static func defaultStore() throws -> LibraryStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return LibraryStore(root: base.appending(path: "WorkshopWallpaperBridge"))
    }

    private var assetsRoot: URL {
        root.appending(path: "Assets")
    }

    private func save(_ manifest: LibraryManifest) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let data = try JSONEncoder.bridge.encode(manifest)
        try data.write(to: root.appending(path: "library.json"), options: [.atomic])
    }

    private func replaceDirectory(target: URL, replacement: URL, backup: URL) throws {
        let exists = FileManager.default.fileExists(atPath: target.path)
        if exists {
            try FileManager.default.moveItem(at: target, to: backup)
        }
        do {
            try FileManager.default.moveItem(at: replacement, to: target)
            if exists {
                try FileManager.default.removeItem(at: backup)
            }
        } catch {
            if exists, FileManager.default.fileExists(atPath: backup.path) {
                try? FileManager.default.moveItem(at: backup, to: target)
            }
            if FileManager.default.fileExists(atPath: replacement.path) {
                try? FileManager.default.removeItem(at: replacement)
            }
            throw error
        }
    }

    private func rewrite(asset: WallpaperAsset, source: URL, target: URL) -> WallpaperAsset {
        WallpaperAsset(
            id: asset.id,
            title: asset.title,
            kind: asset.kind,
            supportStatus: asset.supportStatus,
            source: asset.source,
            projectDirectory: target.path,
            entrypoint: rewrite(path: asset.entrypoint, source: source, target: target),
            thumbnail: rewrite(path: asset.thumbnail, source: source, target: target),
            workshopId: asset.workshopId,
            redistributionAllowed: false,
            issues: asset.issues
        )
    }

    private func rewrite(path: String?, source: URL, target: URL) -> String? {
        guard let path else {
            return nil
        }
        let prefix = source.path.hasSuffix("/") ? source.path : "\(source.path)/"
        guard path.hasPrefix(prefix) else {
            return path
        }
        let relative = String(path.dropFirst(prefix.count))
        return target.appending(path: relative).path
    }
}

private func storageDirectoryName(for id: String) -> String {
    let encoded = Data(id.utf8)
        .base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    return "id-\(encoded)"
}

private extension JSONEncoder {
    static var bridge: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var bridge: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
