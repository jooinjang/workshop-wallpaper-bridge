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
}
