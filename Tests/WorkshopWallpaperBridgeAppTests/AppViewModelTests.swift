import Foundation
import XCTest
@testable import WorkshopWallpaperBridgeApp
import WorkshopWallpaperCore

@MainActor
final class AppViewModelTests: XCTestCase {
    func testInitSelectsFirstLibraryAssetWhenAvailable() throws {
        // Given
        let sourceRoot = try makeTempDirectory()
        let video = sourceRoot.appending(path: "clip.mp4")
        FileManager.default.createFile(atPath: video.path, contents: Data([1]))
        let store = LibraryStore(root: try makeTempDirectory())
        let imported = try store.importVideoFile(video)

        // When
        let model = AppViewModel(
            store: store,
            loginItemController: MockLoginItemController(),
            userDefaults: try makeUserDefaults()
        )

        // Then
        XCTAssertEqual(model.selectedLibraryAssetId, imported.id)
        XCTAssertEqual(model.selectedLibraryAsset, imported)
    }

    func testRemoveSelectedLibraryAssetDeletesImportedCopy() throws {
        // Given
        let sourceRoot = try makeTempDirectory()
        let video = sourceRoot.appending(path: "clip.mp4")
        FileManager.default.createFile(atPath: video.path, contents: Data([1]))
        let store = LibraryStore(root: try makeTempDirectory())
        let imported = try store.importVideoFile(video)
        let model = AppViewModel(
            store: store,
            loginItemController: MockLoginItemController(),
            userDefaults: try makeUserDefaults()
        )
        model.selectedLibraryAssetId = imported.id

        // When
        model.removeSelectedLibraryAsset()
        let manifest = try store.load()

        // Then
        XCTAssertTrue(model.libraryAssets.isEmpty)
        XCTAssertNil(model.selectedLibraryAssetId)
        XCTAssertTrue(manifest.assets.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: imported.projectDirectory))
        XCTAssertTrue(FileManager.default.fileExists(atPath: video.path))
    }

    func testRemoveSelectedLibraryAssetsDeletesMultipleImportedCopies() throws {
        // Given
        let sourceRoot = try makeTempDirectory()
        let firstVideo = sourceRoot.appending(path: "first.mp4")
        let secondVideo = sourceRoot.appending(path: "second.mp4")
        FileManager.default.createFile(atPath: firstVideo.path, contents: Data([1]))
        FileManager.default.createFile(atPath: secondVideo.path, contents: Data([2]))
        let store = LibraryStore(root: try makeTempDirectory())
        let first = try store.importVideoFile(firstVideo)
        let second = try store.importVideoFile(secondVideo)
        let model = AppViewModel(
            store: store,
            loginItemController: MockLoginItemController(),
            userDefaults: try makeUserDefaults()
        )
        model.selectLibraryAssets([first.id, second.id])

        // When
        model.removeSelectedLibraryAssets()
        let manifest = try store.load()

        // Then
        XCTAssertTrue(model.libraryAssets.isEmpty)
        XCTAssertTrue(model.selectedLibraryAssetIds.isEmpty)
        XCTAssertTrue(manifest.assets.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.projectDirectory))
        XCTAssertFalse(FileManager.default.fileExists(atPath: second.projectDirectory))
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstVideo.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondVideo.path))
    }

    func testLaunchAtLoginToggleRegistersLoginItem() throws {
        // Given
        let loginItems = MockLoginItemController()
        let model = AppViewModel(
            store: LibraryStore(root: try makeTempDirectory()),
            loginItemController: loginItems,
            userDefaults: try makeUserDefaults()
        )

        // When
        model.launchAtLogin = true

        // Then
        XCTAssertTrue(loginItems.isEnabled)
        XCTAssertEqual(loginItems.requestedValues, [true])
        XCTAssertEqual(model.status, "Workshop Wallpaper Bridge will open at login.")
    }

    func testLaunchAtLoginToggleRevertsWhenControllerThrows() throws {
        // Given
        let loginItems = MockLoginItemController()
        loginItems.error = TestError.expected
        let model = AppViewModel(
            store: LibraryStore(root: try makeTempDirectory()),
            loginItemController: loginItems,
            userDefaults: try makeUserDefaults()
        )

        // When
        model.launchAtLogin = true

        // Then
        XCTAssertFalse(model.launchAtLogin)
        XCTAssertFalse(loginItems.isEnabled)
        XCTAssertEqual(loginItems.requestedValues, [true])
        XCTAssertTrue(model.status.contains("Open at login could not be changed"))
    }

    func testInitRestoresDisplayPreferences() throws {
        // Given
        let defaults = try makeUserDefaults()
        defaults.set("fill", forKey: "displayMode")
        defaults.set(false, forKey: "autoPauseWhenCovered")

        // When
        let model = AppViewModel(
            store: LibraryStore(root: try makeTempDirectory()),
            loginItemController: MockLoginItemController(),
            userDefaults: defaults
        )

        // Then
        XCTAssertEqual(model.displayMode, .fill)
        XCTAssertFalse(model.autoPauseWhenCovered)
    }

    func testStopPlaybackClearsLastPlayedWallpaperPreference() throws {
        // Given
        let defaults = try makeUserDefaults()
        defaults.set("last-wallpaper", forKey: "lastPlayedAssetId")
        let model = AppViewModel(
            store: LibraryStore(root: try makeTempDirectory()),
            loginItemController: MockLoginItemController(),
            userDefaults: defaults
        )

        // When
        model.stopPlayback()

        // Then
        XCTAssertNil(defaults.string(forKey: "lastPlayedAssetId"))
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    private func makeUserDefaults() throws -> UserDefaults {
        let suiteName = "WorkshopWallpaperBridgeTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

@MainActor
private final class MockLoginItemController: LoginItemManaging {
    var isEnabled = false
    var requestedValues: [Bool] = []
    var error: Error?

    func setEnabled(_ enabled: Bool) throws {
        requestedValues.append(enabled)
        if let error {
            throw error
        }
        isEnabled = enabled
    }

    func openSystemSettings() {}
}

private enum TestError: Error {
    case expected
}
