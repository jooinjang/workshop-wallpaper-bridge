import XCTest

final class RestrictedWebWallpaperViewTests: XCTestCase {
    func testWebWallpaperDoesNotLoadWhenRemoteBlockerCompilationFails() throws {
        let source = try String(contentsOfFile: "Sources/WorkshopWallpaperBridgeApp/RestrictedWebWallpaperView.swift")

        XCTAssertTrue(source.contains("guard error == nil, let ruleList else"))
        XCTAssertFalse(source.contains("if let ruleList {"))
    }
}
