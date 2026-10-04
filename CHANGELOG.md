# Changelog

All notable changes to MIHAD AUDIO are documented in this file.

## [Unreleased]

### Fixed
- Removed the `video_thumbnail` package: its bundled Android
  `build.gradle` references the removed `jcenter()` repository shorthand,
  which fails the actual Gradle "Build debug APK" step under the
  AGP/Gradle versions bundled with current Flutter stable - confirmed by
  a real GitHub Actions run where `analyze`/`test` passed but the APK
  build failed. Replaced with `VideoThumbnailService`, a small local
  thumbnail extractor built on `ffmpeg_kit_flutter_new` (already shipped
  for export) with on-disk caching by video path + modified time. This
  removes an extra native Android plugin entirely and was verified by a
  real passing GitHub Actions build.

### Added
- Real on-device video thumbnails on project cards (`VideoThumbnailImage`,
  via the `video_thumbnail` package), replacing the static gradient-icon
  placeholder whenever a project has a selected source video. Falls back
  to the gradient tile gracefully if thumbnail generation isn't supported
  on a given platform/file.
- `MediaPickResult` / `MediaPickStatus`: the video/audio file pickers now
  return an explicit success/cancelled/error outcome instead of a bare
  nullable path, so a picker failure (permission denied, no file manager
  app available, etc.) surfaces a clear on-screen message instead of
  silently doing nothing or crashing.
- `resolvePick()` helper (`lib/widgets/pick_feedback.dart`) centralizing
  the SnackBar-on-error UX across every "pick a video/audio" entry point
  (home screen project creation, editor reselect-video/audio, editor
  audio-source picker).
- Expanded automated test coverage from 33 to 55 tests: full CRUD and
  reload/persistence coverage for `ProjectsLibraryProvider` (create,
  rename, delete, upsert, recency sorting, exports aggregation, and a
  simulated "reopen the app" round trip through a fresh provider
  instance backed by the same on-disk storage), round-trip and
  defaulting coverage for `AppSettingsProvider`/`AppSettings`, pure-Dart
  coverage of the new `MediaPickResult` factories, and widget tests for
  `resolvePick()`'s SnackBar/no-SnackBar behavior.
- Shared `FakePathProvider` test helper (`test/fake_path_provider.dart`)
  so every persistence-layer test runs against an isolated temp
  directory instead of hitting real device storage.

### Changed
- Editor playback bar (`_PlaybackBar`) now drives playback exclusively
  through `EditorProvider.play()` / `.pause()` / `.seekTo()` instead of
  calling the raw `VideoPlayerController` directly, keeping a single
  source of truth for playback state.
- The audio-source volume slider now calls `editor.setAudioVolume(v)`
  directly on every drag tick instead of reconstructing and resubmitting
  a full `AudioSourceConfig` (which re-triggered audio analysis on every
  tick) via `setAudioSource`.

### Fixed
- A `PlatformException` thrown by the system file picker (e.g. the user
  denies storage permission, or no picker app is available) is now
  caught and reported to the user instead of propagating uncaught.
