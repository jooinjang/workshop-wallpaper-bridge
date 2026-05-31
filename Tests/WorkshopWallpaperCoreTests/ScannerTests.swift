import Foundation
import XCTest
@testable import WorkshopWallpaperCore

final class ScannerTests: XCTestCase {
    func testScanDiscoversPlayableVideoWhenWorkshopFolderContainsProjectJson() throws {
        // Given
        let root = try Fixture.makeWorkshopRoot()
        let project = root.appending(path: "123456")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        try #"{"title":"Rain Loop","file":"rain.mp4","type":"video"}"#.write(
            to: project.appending(path: "project.json"),
            atomically: true,
            encoding: .utf8
        )
        FileManager.default.createFile(atPath: project.appending(path: "rain.mp4").path, contents: Data())

        // When
        let result = try WallpaperScanner().scan(root: root)

        // Then
        XCTAssertEqual(result.assets.count, 1)
        let asset = try XCTUnwrap(result.assets.first)
        XCTAssertEqual(asset.id, "123456")
        XCTAssertEqual(asset.title, "Rain Loop")
        XCTAssertEqual(asset.kind, .video)
        XCTAssertEqual(asset.supportStatus, .playable)
        XCTAssertEqual(asset.source, .localSteamWorkshop)
        XCTAssertEqual(asset.redistributionAllowed, false)
    }

    func testScanClassifiesWebImageAndSceneProjects() throws {
        // Given
        let root = try Fixture.makeTempDirectory()
        try Fixture.project(root: root, id: "web", metadata: #"{"title":"Clock","file":"index.html"}"#, file: "index.html")
        try Fixture.project(root: root, id: "image", metadata: #"{"title":"Poster","file":"poster.png"}"#, file: "poster.png")
        try Fixture.project(root: root, id: "scene", metadata: #"{"title":"Particles","file":"scene.pkg"}"#, file: "scene.pkg")

        // When
        let result = try WallpaperScanner().scan(root: root)

        // Then
        XCTAssertEqual(result.assets.map(\.kind), [.image, .scene, .web])
        XCTAssertEqual(result.assets.map(\.supportStatus), [.playable, .unsupported, .playable])
    }

    func testScanReportsMalformedProjectJsonWithoutThrowing() throws {
        // Given
        let root = try Fixture.makeTempDirectory()
        let project = root.appending(path: "broken")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        try "{bad json".write(to: project.appending(path: "project.json"), atomically: true, encoding: .utf8)
        FileManager.default.createFile(atPath: project.appending(path: "clip.mp4").path, contents: Data())

        // When
        let result = try WallpaperScanner().scan(root: root)

        // Then
        XCTAssertEqual(result.assets.count, 1)
        let asset = try XCTUnwrap(result.assets.first)
        XCTAssertEqual(asset.kind, .video)
        XCTAssertTrue(asset.issues.contains { $0.code == "malformed_project_json" })
    }
}
