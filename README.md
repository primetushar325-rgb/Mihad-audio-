# MIHAD AUDIO

**An offline, audio-reactive video visualizer editor for Android.**

MIHAD AUDIO lets you pick a video, choose an animated audio visualizer
template, position and style it over the video, preview it live, and
export a real MP4 with the visualizer baked in and synced to the audio —
entirely on your phone. No account, no cloud upload, no API keys, no
subscription, no internet connection required for any core feature.

> **Status: functional MVP.** Import, playback, on-device audio analysis,
> all 10 visualizer templates, live drag/resize customization, and a real
> local MP4 export pipeline are implemented and covered by automated
> tests (see [Testing](#testing-status) for exactly what has and hasn't
> been verified on a physical device). Performance on very long videos is
> a known limitation — see [Known limitations](#known-limitations-and-honest-caveats).

---

## Table of contents

- [Features](#features)
- [How it works (technical overview)](#how-it-works-technical-overview)
- [Tech stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Local development setup](#local-development-setup)
- [Running the app](#running-the-app)
- [Building an APK locally](#building-an-apk-locally)
- [Building via GitHub Actions (recommended)](#building-via-github-actions-recommended)
- [Project structure](#project-structure)
- [Permissions](#permissions)
- [Privacy](#privacy)
- [Dependency licenses](#dependency-licenses)
- [Supported formats](#supported-formats)
- [Known limitations and honest caveats](#known-limitations-and-honest-caveats)
- [Testing status](#testing-status)
- [Troubleshooting](#troubleshooting)

## Features

- **Home screen** — Create New Project, Recent Projects, My Exports,
  Template Gallery, Settings, app version — all backed by real local
  state, nothing is a static mockup.
- **Video import** — system file/gallery picker (Storage Access
  Framework), shows duration/resolution/aspect ratio via on-device
  FFprobe, lets you replace the video at any time.
- **Audio source** — use the video's own embedded audio track, or pick a
  separate audio file from the device, with a volume control.
- **On-device audio analysis** — the audio track is decoded locally
  (bundled, offline FFmpeg binary) and analyzed with a real FFT
  (`fftea`) into per-frame amplitude + 32 frequency bands, smoothed to
  avoid flicker and safe against silence/clipping.
- **10 real, audio-reactive visualizer templates** — Classic Waveform,
  Equalizer Bars, Circular Spectrum, Minimal Line Wave, Neon Wave, Dual
  Waveform, Dot Spectrum, Mirror Bars, Pulse Circle, Vertical Frequency
  Bars. Each one is a Flutter `CustomPainter` driven by the actual
  analyzed audio — not a static image or an unrelated loop.
- **Customization** — drag to reposition, drag the corner handle to
  resize, primary/secondary color, opacity, glow intensity, sensitivity,
  bar/line thickness, horizontal alignment, aspect ratio (16:9, 9:16,
  1:1, original), and a one-tap reset.
- **Live preview** — the video plays with the visualizer rendered on top
  in real time, reacting to the real analyzed audio, matching the exact
  position/size that will be used in the final export.
- **Local MP4 export** — renders the exact visualizer as a transparent
  frame sequence, composites it onto the source video with the chosen
  audio track using the bundled FFmpeg binary, and encodes a real H.264 /
  AAC MP4 — with progress, cancel, and resolution/FPS choices.
- **Local project management** — JSON-backed projects (no database
  engine needed) with rename/delete, and an export history.
- **Settings** — default export resolution/FPS/color, preview quality,
  temporary storage usage + a working "Clear temporary files" action,
  and an auto-generated open-source licenses page.

## How it works (technical overview)

```
Video/audio file (on-device)
        │
        ▼
 FFprobe (ffmpeg_kit_flutter_new) ── duration / resolution / fps
        │
        ▼
 FFmpeg → raw PCM  ──►  fftea FFT  ──►  AudioAnalysisData
                                        (amplitude + 32 bands per frame)
        │
        ▼
 Live preview: VideoPlayer + CustomPainter overlay, reading
 AudioAnalysisData at the current playback position
        │
        ▼
 Export: the SAME CustomPainter renders every output frame to a
 transparent PNG → FFmpeg assembles a lossless alpha overlay clip →
 FFmpeg composites it over the source video + chosen audio → H.264/AAC MP4
```

Using the *same* painter and the *same* fractional position/size data
for both the live preview and the final export frame-render is what
keeps what-you-see-in-preview matching what-you-get-in-the-exported-file
(see `lib/services/export_math.dart` and
`lib/widgets/visualizer_overlay_editor.dart`).

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| UI framework | Flutter (stable) | Cross-platform widgets + `CustomPainter` for real-time graphics |
| Language | Dart (+ no custom native Kotlin was needed) | |
| State management | `provider` | Small, explicit, easy to audit |
| File/media picking | `file_picker`, `video_player`, `video_thumbnail` | Maintained, SAF-based, no permission over-reach |
| Audio decode + video render | `ffmpeg_kit_flutter_new` | Actively maintained (2025) community fork; original `ffmpeg_kit_flutter` was retired/archived in Jan 2025 — **do not use it in new code** |
| FFT / frequency analysis | `fftea` | Pure Dart, MIT-licensed, no native code needed |
| Local persistence | plain JSON files via `path_provider` | Transparent, no embedded database engine |
| Save to gallery | `gal` | Minimal permissions, scoped-storage aware |
| Build/CI | GitHub Actions, GitHub-hosted `ubuntu-latest` runners | Free, no self-hosted infra |

## Prerequisites

- Flutter SDK (stable channel). This project was built and verified
  against Flutter `3.47.x` / Dart `3.13.x`; any current stable release
  should work.
- Android toolchain (Android SDK + a JDK compatible with Gradle, e.g.
  JDK 17) **only if you want to build the APK on your own machine**. If
  you only want the GitHub Actions build, you don't need any of this
  locally.
- An Android device or emulator (API 24 / Android 7.0+) to actually run
  and test the app — video/audio decoding, FFT, and FFmpeg rendering
  cannot be meaningfully tested in a desktop/CI-only environment.

## Local development setup

```bash
git clone <this-repo-url>
cd mihad_audio
flutter pub get
```

## Running the app

```bash
flutter devices        # confirm a device/emulator is attached
flutter run             # debug build, hot reload
```

## Building an APK locally

```bash
flutter build apk --debug      # fastest, for your own testing
flutter build apk --release    # uses the debug signing config by default;
                                 # see "Release signing" below before shipping
```

The resulting APK is at `build/app/outputs/flutter-apk/app-debug.apk`
(or `app-release.apk`).

### Release signing (not yet configured)

This repository currently ships a **debug-signed** build only, as
required by the project brief for the initial version. To add a real
release signing config later:

1. Generate a keystore (`keytool -genkey ...`), **never commit it**.
2. Add `android/key.properties` (already in `.gitignore`) with your
   keystore path/passwords.
3. Reference it from `android/app/build.gradle.kts`'s `signingConfigs`.
4. In CI, store the keystore (base64-encoded) and its passwords as
   **GitHub Secrets**, decode them in a workflow step, and never print
   or commit them.

## Building via GitHub Actions (recommended)

A workflow at [`.github/workflows/android-build.yml`](.github/workflows/android-build.yml)
builds a debug APK on GitHub's own `ubuntu-latest` runners — your video
files are **never involved** in this step; it only compiles the app.

1. Push this repository to GitHub (or use your fork).
2. Go to the **Actions** tab → **Android Build** → **Run workflow**
   (it also runs automatically on every push to `main`).
3. Wait for the job to finish. It runs `dart format` (check),
   `flutter analyze`, `flutter test`, then `flutter build apk --debug`.
4. Open the finished run and download the **`mihad-audio-debug-apk`**
   artifact — that zip contains `app-debug.apk`.
5. Transfer the APK to your Android phone and install it (you'll need to
   allow "install unknown apps" for whichever app you use to open it).

> This repository does not claim a workflow run has succeeded unless you
> have actually run it and seen it go green in the Actions tab — a
> description of a CI workflow is not the same as a passing CI run.

## Project structure

```
lib/
  app/            # MaterialApp setup, theme
  models/         # Plain Dart data models (Project, VisualizerSettings, ...)
  services/       # Media picking, FFprobe, audio analysis, export (FFmpeg)
  state/          # ChangeNotifier providers (editor, projects, settings, export)
  visualizers/    # CustomPainter implementations for all 10 templates
  screens/        # Home, Editor, Template Gallery, Export, Settings
  widgets/        # Reusable UI pieces (overlay editor, color picker, cards)
android/          # Standard Flutter Android project
assets/icons/     # Original app icon source (AI-generated artwork, no third-party logos)
test/             # Unit + widget tests (see Testing status)
.github/workflows/android-build.yml
```

## Permissions

MIHAD AUDIO requests the **minimum** permissions needed and explains why
each one exists (see `android/app/src/main/AndroidManifest.xml`):

| Permission | Why | Notes |
|---|---|---|
| `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 28) | So exported videos can be saved to the shared gallery on Android 9 and below | Not requested at all on Android 10+, where scoped storage / `MediaStore` handles this without a broad permission |

**No `INTERNET` permission is requested**, because no core feature needs
network access. Picking a video/audio file uses the Android system
picker (Storage Access Framework) and does not require a storage
permission either.

## Privacy

- No account, no login, no analytics, no advertising identifiers.
- No video, audio, thumbnail, or project file is ever uploaded anywhere.
- All audio analysis and all video rendering happen in-process, on the
  device, using bundled native binaries (FFmpeg) — not a remote service.
- Project data is stored as plain JSON files in the app's own private
  storage directory.

## Dependency licenses

Full list is generated automatically in-app: **Settings → About →
Open-source licenses** (uses Flutter's built-in `showLicensePage`,
populated from every package's bundled `LICENSE` file).

The one dependency that materially affects *this repository's own*
license is:

- **`ffmpeg_kit_flutter_new`** bundles a **full-GPL** build of FFmpeg
  (it includes GPL-licensed components such as `libx264`). Distributing
  a compiled app that links against it means the distributed binary is
  governed by the GPL's copyleft terms. **This is why this repository is
  licensed under GPL-3.0** (see [`LICENSE`](LICENSE)) rather than a
  permissive license — keeping the full source available here satisfies
  that obligation.
  - If you need a permissively-licensed (e.g. MIT/Apache) distribution
    later, you would need to replace the FFmpeg-based renderer with a
    non-GPL approach (e.g. Android's native `MediaCodec`/`MediaMuxer`
    APIs), which is a materially larger engineering effort noted in
    [Known limitations](#known-limitations-and-honest-caveats).
- **`fftea`** (Apache-2.0) — pure-Dart FFT, no copyleft implications.
- Everything else (`file_picker`, `video_player`, `provider`, `gal`,
  `path_provider`, `uuid`, `path`, `package_info_plus`,
  `video_thumbnail`, `just_audio`) uses permissive (BSD/MIT/Apache-2.0)
  licenses at the time of writing — always re-check current license
  terms before shipping, since they can change between versions.

## Supported formats

- **Video import:** whatever your Android device's `video_player` +
  decoder stack supports — in practice, MP4/H.264 is the most reliable;
  MOV works where the on-device decoder supports it. Unsupported files
  show a clear in-app error asking you to pick a different file (never a
  silent failure or a crash).
- **Audio:** any format the bundled FFmpeg build can decode (MP3, AAC/M4A,
  WAV, OGG, FLAC, and more).
- **Export:** H.264 video / AAC audio inside an `.mp4` container, at
  720p, 1080p, or the source resolution, at 24fps/30fps/source fps.

## Known limitations and honest caveats

- **Export speed on long videos.** The export pipeline renders every
  output frame as a separate PNG (to guarantee the visualizer matches
  preview pixel-for-pixel) before encoding. This is reliable but is
  **not real-time** — a 10-60 minute video can take a long time and use
  significant battery/storage on a phone. **Test with a short clip (under
  ~1 minute) first.** The in-app Export screen shows a warning for videos
  5+ minutes long.
- **No automatic low-storage pre-check.** There is no portable, reliable
  way to query free disk space from pure Dart without an extra
  dependency. Instead, the export pipeline catches write failures (e.g.
  `ENOSPC`) and surfaces a clear "not enough storage" message rather than
  silently failing or corrupting output — but it cannot warn you *before*
  starting if space is tight.
- **GPL-licensed renderer.** See [Dependency licenses](#dependency-licenses)
  above — this is a real legal/architectural constraint, not an
  oversight.
- **No automated on-device test run.** The automated test suite
  (`flutter test`) and GitHub Actions CI validate app logic, UI
  navigation, and that the project compiles — they run on a desktop/CI
  Linux Dart VM, not on a physical Android phone. Please see
  [Testing status](#testing-status) below for exactly what still needs a
  manual pass on real hardware.
- **No light theme.** MIHAD AUDIO is dark-only by design; the Settings
  screen states this rather than offering a non-functional toggle.

## Testing status

Automated (`flutter test`, also run in CI):

- ✅ App startup renders the Home screen (title, Create New Project,
  Recent Projects, My Exports).
- ✅ Template Gallery navigation + template selection.
- ✅ All 10 visualizer templates are registered and paint without
  throwing, for both loud and silent synthetic audio data.
- ✅ `VisualizerSettings` JSON round-trip, `copyWith`, and
  `resetAppearance` (position/size/appearance calculations).
- ✅ `Project` JSON round-trip, including nested audio source/visualizer
  settings/export settings, and safe fallback on malformed/missing data.
- ✅ `AudioAnalysisData` frame lookup and out-of-range clamping logic.
- ✅ Export resolution/FPS/aspect-ratio resolution math
  (`export_math.dart`), including odd-dimension and missing-metadata
  edge cases.
- ✅ `dart format` and `flutter analyze` run clean (also enforced in CI).
- ✅ GitHub Actions workflow YAML — validated by the workflow's own
  successful execution once you run it in your repository (this
  repository does not claim a run on your behalf).

**Not automatable / requires a manual pass on a physical Android device**
(please verify before relying on this app for anything important):

- ⬜ Real video import from the gallery/file picker on-device.
- ⬜ Real original-video-audio playback and analysis timing accuracy.
- ⬜ Real separate-audio-file selection and mixing.
- ⬜ Real audio-reactive animation quality/smoothness on real music.
- ⬜ Visualizer drag/resize touch ergonomics on various screen sizes.
- ⬜ A full real MP4 export end-to-end, and that the exported file plays
  correctly in a standard video player with visualizer + audio in sync.
- ⬜ Saving to the system gallery (`gal`) across Android versions.
- ⬜ Reopening a project after the app has been fully restarted.
- ⬜ Behavior under low storage / interrupted export / backgrounding.

If you hit an issue in any of the "not automatable" items above, please
open a GitHub issue with your Android version and a short repro video if
possible.

## Troubleshooting

- **"This video format could not be opened"** — try re-encoding to
  H.264/MP4 with a tool like HandBrake, then re-import.
- **Audio analysis fails / "no usable audio track"** — the file may have
  an audio codec the bundled FFmpeg build can't decode, or no audio
  track at all; pick a different file.
- **Export is very slow** — expected for long videos (see
  [Known limitations](#known-limitations-and-honest-caveats)); try a
  shorter clip, a lower resolution/fps, or a less glow-heavy template.
- **Build fails locally with a Gradle/Java error** — make sure you're on
  JDK 17+ and a current Flutter stable release; this is exactly what the
  GitHub Actions workflow pins, so it's a good reference environment.
- **`flutter_launcher_icons`/icon looks default** — re-run
  `dart run flutter_launcher_icons` after `flutter pub get` if you've
  changed `assets/icons/app_icon.png`.

---

MIHAD AUDIO's own project code is licensed under **GPL-3.0** — see
[`LICENSE`](LICENSE). Third-party packages keep their own licenses
(viewable in-app under Settings → About → Open-source licenses).
