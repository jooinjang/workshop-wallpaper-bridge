import Foundation
import XCTest
@testable import WorkshopWallpaperCore

final class LibraryStoreTests: XCTestCase {
    func testImportCopiesProjectIntoLibraryAndPersistsManifest() throws {
        // Given
        let sourceRoot = try Fixture.makeTempDirectory()
        try Fixture.project(root: sourceRoot, id: "777", metadata: #"{"title":"Neon","file":"neon.mp4"}"#, file: "neon.mp4")
        let asset = try XCTUnwrap(WallpaperScanner().scan(root: sourceRoot).assets.first)
        let store = LibraryStore(root: try Fixture.makeTempDirectory())

        // When
        let imported = try store.importAsset(asset)
        let manifest = try store.load()

        // Then
        XCTAssertEqual(manifest.assets.map(\.id), ["777"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: imported.projectDirectory))
        XCTAssertTrue(FileManager.default.fileExists(atPath: URL(filePath: imported.projectDirectory).appending(path: "neon.mp4").path))
        XCTAssertEqual(imported.redistributionAllowed, false)
    }

    func testImportKeepsDistinctStorageForIdsThatNormalizeSimilarly() throws {
        // Given
        let sourceRoot = try Fixture.makeTempDirectory()
        try Fixture.project(root: sourceRoot, id: "a b", metadata: #"{"title":"Space","file":"space.mp4"}"#, file: "space.mp4")
        try Fixture.project(root: sourceRoot, id: "a_b", metadata: #"{"title":"Underscore","file":"under.mp4"}"#, file: "under.mp4")
        let assets = try WallpaperScanner().scan(root: sourceRoot).assets
        let store = LibraryStore(root: try Fixture.makeTempDirectory())

        // When
        let imported = try assets.map { try store.importAsset($0) }
        let manifest = try store.load()

        // Then
        XCTAssertEqual(manifest.assets.map(\.id), ["a b", "a_b"])
        XCTAssertEqual(Set(imported.map(\.projectDirectory)).count, 2)
        XCTAssertTrue(imported.allSatisfy { FileManager.default.fileExists(atPath: $0.projectDirectory) })
    }
}
