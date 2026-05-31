# Workshop Wallpaper Bridge

**Workshop Wallpaper Bridge**는 Windows에서 Wallpaper Engine을 구매해서 사용하던 사람이, 본인이 가진 Workshop 프로젝트 폴더를 Mac으로 복사한 뒤 개인용 움직이는 배경화면으로 쓰기 위한 macOS 앱입니다.

Steam Workshop 자료를 다운로드하지 않습니다. Steam 인증을 우회하지 않습니다. `scene.pkg`를 풀거나 역공학하지 않습니다. 다른 제작자의 자료를 재배포하는 기능도 없습니다. 이미 내 컴퓨터에 있는 폴더만 읽고, 지원 가능한 프로젝트를 로컬 라이브러리에 복사한 뒤 macOS 데스크톱 레벨 창에서 재생합니다.

[English README](README.md)

## 왜 만들었나

Wallpaper Engine은 Windows와 Android를 공식 지원합니다. 하지만 Windows에서 이미 구매하고 구독해 둔 Workshop 자료가 있는 사용자는 보통 아래 경로에 로컬 파일을 가지고 있습니다.

```text
C:\Program Files (x86)\Steam\steamapps\workshop\content\431960
```

이 폴더를 Mac으로 복사하면, 이 앱이 프로젝트를 스캔하고 지원 가능한 자료를 가져와 Mac 배경화면처럼 재생합니다.

## 지원 범위

| Wallpaper Engine 프로젝트 유형 | macOS 지원 |
| --- | --- |
| Video: `.mp4`, `.mov`, `.m4v` | 바로 데스크톱에서 재생 |
| Video: `.webm`, `.mkv`, `.avi` | 로컬 `ffmpeg`로 변환 후 재생 |
| Web: `index.html` | 데스크톱 레벨 `WKWebView`로 재생 |
| Image: `.jpg`, `.png`, `.gif`, `.heic` | 정적 배경 레이어로 표시 |
| Scene: `scene.pkg` | 감지는 하지만 해체/변환하지 않음 |

## 안전 경계

이 프로젝트는 의도적으로 보수적으로 설계했습니다.

- Steam Workshop downloader 없음
- Steam 인증 우회 없음
- DRM 우회 없음
- Steam protocol emulation 없음
- `scene.pkg` 역공학 없음
- 공유, marketplace, 재업로드 기능 없음
- 원본 Workshop 폴더 수정 없음

가져온 파일은 아래 위치에 복사됩니다.

```text
~/Library/Application Support/WorkshopWallpaperBridge
```

로컬 manifest에는 모든 asset이 `redistributionAllowed: false`로 저장됩니다.

## 소스에서 실행

필요한 것:

- macOS 14 이상
- Xcode command line tools
- Swift 6 toolchain
- 선택: WebM/MKV/AVI 변환용 `ffmpeg`

```bash
git clone https://github.com/3x-haust/workshop-wallpaper-bridge.git
cd workshop-wallpaper-bridge
swift run WorkshopWallpaperBridge
```

`ffmpeg` 설치:

```bash
brew install ffmpeg
```

## 앱 패키징

```bash
bash Scripts/package-app.sh
open "dist/Workshop Wallpaper Bridge.app"
```

생성되는 zip:

```text
dist/WorkshopWallpaperBridge-macOS-arm64.zip
```

## CLI

자동화와 검증을 위해 `wwbctl`도 제공합니다.

```bash
swift run wwbctl scan "/path/to/431960" --out index.json
swift run wwbctl import "/path/to/431960"
swift run wwbctl convert input.webm --out output.mp4
swift run wwbctl doctor
```

## 사용 흐름

1. Windows에서 Steam과 Wallpaper Engine을 정상적으로 사용합니다.
2. `steamapps/workshop/content/431960` 폴더를 Mac으로 복사합니다.
3. Workshop Wallpaper Bridge를 엽니다.
4. 복사한 폴더를 선택하고 스캔합니다.
5. 지원 가능한 프로젝트를 로컬 라이브러리로 가져옵니다.
6. 가져온 video, web, image 프로젝트를 선택합니다.
7. **Play on Desktop**을 누릅니다.

움직이는 배경화면이 재생되는 동안 앱은 계속 실행되어 있어야 합니다.

## 프로젝트 구조

```text
Sources/WorkshopWallpaperCore        스캐너, manifest, importer, converter
Sources/WorkshopWallpaperBridgeApp   SwiftUI 앱과 데스크톱 배경 재생기
Sources/wwbctl                       CLI entrypoint
Tests/WorkshopWallpaperCoreTests     스캐너와 라이브러리 테스트
Scripts/package-app.sh               로컬 .app/zip 패키징
```

## Wallpaper Engine과의 관계

이 프로젝트는 Valve, Steam, Wallpaper Engine과 관련이 없는 비공식 프로젝트입니다. Wallpaper Engine은 해당 소유자의 상표입니다. Workshop Wallpaper Bridge는 사용자가 합법적으로 접근할 수 있는 로컬 파일을 개인적으로 활용하기 위한 호환 도구입니다.

## 라이선스

MIT
