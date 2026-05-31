# Workshop Wallpaper Bridge

**Workshop Wallpaper Bridge** is a local-only macOS app for people who bought Wallpaper Engine on Windows and want to reuse their own copied Workshop projects on a Mac.

It does not download Steam Workshop items, bypass Steam, unpack proprietary `scene.pkg` files, or redistribute creator assets. It reads folders that already exist on your machine, copies supported projects into a private local library, and plays video, web, and image wallpapers as a desktop-level macOS background.

[한국어 README](README.ko.md)

## Why This Exists

Wallpaper Engine is Windows and Android software. Many users still have legitimate Workshop projects on a Windows Steam install, usually under:

```text
C:\Program Files (x86)\Steam\steamapps\workshop\content\431960
```

If you copy that folder to your Mac, this app helps you scan it, import supported wallpapers, and play them locally.

## What Works

| Wallpaper Engine project type | macOS support |
| --- | --- |
| Video: `.mp4`, `.mov`, `.m4v` | Plays directly on the desktop |
| Video: `.webm`, `.mkv`, `.avi` | Can be converted with local `ffmpeg` |
| Web: `index.html` | Plays in a desktop-level `WKWebView` |
| Image: `.jpg`, `.png`, `.gif`, `.heic` | Plays as a static desktop background layer |
| Scene: `scene.pkg` | Detected, but not unpacked or converted |

## Safety Boundaries

Workshop Wallpaper Bridge is intentionally conservative.

- No Steam Workshop downloader
- No Steam authentication bypass
- No DRM bypass
- No Steam protocol emulation
- No `scene.pkg` reverse engineering
- No sharing, marketplace, or re-upload workflow
- No modification of the original Workshop folder

Imported files are copied into:

```text
~/Library/Application Support/WorkshopWallpaperBridge
```

Every imported asset keeps `redistributionAllowed: false` in the local manifest.

## Install From Source

Requirements:

- macOS 14 or newer
- Xcode command line tools
- Swift 6 toolchain
- Optional: `ffmpeg` for WebM/MKV/AVI conversion

```bash
git clone https://github.com/3x-haust/workshop-wallpaper-bridge.git
cd workshop-wallpaper-bridge
swift run WorkshopWallpaperBridge
```

To install `ffmpeg`:

```bash
brew install ffmpeg
```

## Package The App

```bash
bash Scripts/package-app.sh
open "dist/Workshop Wallpaper Bridge.app"
```

The script also creates:

```text
dist/WorkshopWallpaperBridge-macOS-arm64.zip
```

## CLI

The app ships with `wwbctl` for automation and testing.

```bash
swift run wwbctl scan "/path/to/431960" --out index.json
swift run wwbctl import "/path/to/431960"
swift run wwbctl convert input.webm --out output.mp4
swift run wwbctl doctor
```

## Workflow

1. On Windows, use Steam and Wallpaper Engine normally.
2. Copy your local Workshop folder, usually `steamapps/workshop/content/431960`, to your Mac.
3. Open Workshop Wallpaper Bridge.
4. Choose the copied folder and scan.
5. Import supported projects into the local library.
6. Select an imported video, web, or image project.
7. Press **Play on Desktop**.

The app must keep running while the animated wallpaper is playing.

## Project Layout

```text
Sources/WorkshopWallpaperCore        scanner, manifest, importer, converter
Sources/WorkshopWallpaperBridgeApp   SwiftUI app and desktop wallpaper player
Sources/wwbctl                       CLI entrypoint
Tests/WorkshopWallpaperCoreTests     scanner and library tests
Scripts/package-app.sh               local .app and zip packaging
```

## Relationship To Wallpaper Engine

This project is not affiliated with Valve, Steam, or Wallpaper Engine. Wallpaper Engine is a trademark of its respective owner. Workshop Wallpaper Bridge is a compatibility tool for personal local use with files you already have lawful access to.

## License

MIT
