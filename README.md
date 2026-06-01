# Workshop Wallpaper Bridge

Use your own Wallpaper Engine Workshop projects on macOS.

Workshop Wallpaper Bridge is for people who already bought Wallpaper Engine on Windows and copied their local Workshop folder to a Mac. It scans that copied folder, imports supported wallpapers into a private Mac library, and plays video, web, and image wallpapers on the desktop layer.

[한국어 README](README.ko.md)

## Quick Start

1. On Windows, find your Wallpaper Engine Workshop folder:

   ```text
   C:\Program Files (x86)\Steam\steamapps\workshop\content\431960
   ```

2. Copy the `431960` folder to your Mac.
3. Download `WorkshopWallpaperBridge-macOS-arm64.dmg` from the latest GitHub release.
4. Open the DMG, drag **Workshop Wallpaper Bridge.app** to **Applications**, then open it.
5. Click the menu bar icon, then choose **Open Settings**.
6. For Wallpaper Engine projects, click **Browse**, choose the copied `431960` folder, then click **Scan**.
7. Select a supported project and click **Import Selected**.
8. For your own video, click **Add Video File** instead.
9. Select the imported project or video and click **Play on Desktop**.
10. Choose **Display**:
    - **Fit** keeps the full wallpaper visible and may show letterboxing.
    - **Fill** covers the screen like Wallpaper Engine's cover-style modes and may crop the edges.
    - **Stretch** fills the screen exactly and may distort the image.
11. Use **Remove** to delete an imported item from the Mac library without touching the original copied folder or video.

The app runs as a menu bar utility. It does not stay in the Dock or app switcher, and the settings window can be closed while animated wallpapers continue running on the desktop layer.

## Playback Behavior

- **Auto-pause behind apps** is enabled by default.
- Minimizing or hiding the Workshop Wallpaper Bridge control window does not stop playback.
- Closing the settings window does not quit the app. Use **Quit** from the menu bar icon when you want to fully stop the background utility.
- When another app covers the desktop, video playback pauses while the wallpaper layer stays in place.
- When you return to the desktop, playback resumes automatically.
- After sleep/wake or monitor changes, the app recreates the wallpaper windows and resumes the selected wallpaper.
- You can disable auto-pause from the menu bar icon or the settings window if you want continuous playback.
- Turn on **Open at Login** if you want the menu bar utility to start automatically after logging in. The last played wallpaper is restored on app launch unless you press **Stop Playback** first.
- Use **Remove** in the imported library list to delete copied Mac-library files you no longer want.

## Performance Snapshot

Measured on an Apple M2 Mac running macOS 26.2 with a local MP4 wallpaper:

- Launch-to-process average: 69.8 ms across 5 cold opens.
- Playback sample: 2.35% average CPU and 107.1 MB average RSS over 20 seconds.
- Video still-frame extraction: 231.7 ms average across 5 runs.
- Current local library scan: 466 ms.

## Lock Screen And Still Wallpaper

macOS does not provide a stable public API for third-party animated Lock Screen wallpapers. This app does not register custom animated Lock Screen videos or patch Apple's Aerial wallpaper database.

What the app can do safely:

- Set a still image as the macOS desktop wallpaper.
- For MP4, MOV, and M4V video wallpapers, extract a still frame from the video instead of using a tiny Workshop preview GIF.
- Write the same still image to the current user's macOS Lock Screen cache when that cache is available.

Use **Set Still Wallpaper** on an imported project. Direct-play video projects use a generated frame from the video file; WebM, MKV, and AVI projects must be converted first. Image and scene projects use a still preview when one exists. If macOS has already cached a Lock Screen image, the visible Lock Screen may update after locking, logging out, or the next wallpaper refresh.

## Supported Projects

| Project type | Support |
| --- | --- |
| `.mp4`, `.mov`, `.m4v` video | Plays directly |
| `.webm`, `.mkv`, `.avi` video | Convert with local `ffmpeg`, then play |
| `index.html` web wallpaper | Plays locally in a restricted WebView |
| `.jpg`, `.png`, `.gif`, `.heic` image | Displays as a static desktop layer |
| `scene.pkg` scene wallpaper | Detected and inspected for scene contents; not rendered yet |

You can also add your own local video with **Add Video File**. MP4, MOV, and M4V play directly. WebM, MKV, and AVI are imported first, then converted locally with `ffmpeg`.

Workshop preview files such as `preview.jpg`, `thumbnail.jpg`, or `cover.png` are treated as thumbnails, not as the real wallpaper content. If a Workshop project only contains `scene.pkg` plus a preview image, the app marks it as unsupported instead of stretching the low-resolution preview across your screen. The scanner now reads safe `scene.pkg` metadata such as image layers, particles, effects, shaders, audio, models, and `.tex` textures so you can tell why a full renderer is required. Full playback still needs the 1.0 scene renderer; simple unpacking is not enough.

## What This App Will Not Do

Workshop Wallpaper Bridge is local-only.

- It does not download Steam Workshop items.
- It does not bypass Steam authentication.
- It does not bypass DRM.
- It does not emulate Steam protocols.
- It does not claim full `scene.pkg` runtime compatibility.
- It does not upload, share, or redistribute creator assets.
- It does not modify your original copied Workshop folder.

Imported files are copied into:

```text
~/Library/Application Support/WorkshopWallpaperBridge
```

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

Install `ffmpeg`:

```bash
brew install ffmpeg
```

## Build A Local App Bundle

```bash
bash Scripts/package-app.sh
open "dist/Workshop Wallpaper Bridge.app"
```

The script creates:

```text
dist/WorkshopWallpaperBridge-macOS-arm64.dmg
```

## CLI

`wwbctl` is included for advanced users and testing.

```bash
swift run wwbctl scan "/path/to/431960" --out index.json
swift run wwbctl import "/path/to/431960"
swift run wwbctl import-video "/path/to/video.mp4"
swift run wwbctl remove "<asset-id>"
swift run wwbctl convert input.webm --out output.mp4
swift run wwbctl scene-info "/path/to/scene.pkg"
swift run wwbctl doctor
```

## Troubleshooting

If nothing appears on the desktop:

- Check that the imported project is marked `playable`.
- Press **Stop**, then **Play on Desktop** again.
- Temporarily turn off **Auto-pause behind apps**.
- Make sure you are looking at the desktop, not a full-screen app Space.

If the wallpaper looks blurry or cropped:

- Choose **Fit** to keep the full image/video visible.
- Choose **Fill** if you want the screen fully covered and accept edge cropping.
- Check whether the Workshop item is a `scene.pkg` project. Scene-only projects are detected but not rendered, so a preview thumbnail is not used as a fake wallpaper.

If WebM/MKV/AVI conversion fails:

```bash
brew install ffmpeg
```

If macOS warns that the app is from an unidentified developer, that means the release is not notarized yet. You can still build from source with Swift.

## Relationship To Wallpaper Engine

This project is not affiliated with Valve, Steam, or Wallpaper Engine. Wallpaper Engine is a trademark of its respective owner. Workshop Wallpaper Bridge is a compatibility tool for personal local use with files you already have lawful access to.

## License

MIT
