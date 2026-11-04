# Contributing to CheatIME

## Requirements

- Xcode 27, or the Command Line Tools with the macOS 27 SDK (Swift 6.2 or later)
- The macOS 27 SDK is needed only to build. The app targets macOS 15, so the result runs on macOS 15 or later.

## Build and run

```sh
make            # build CheatIME.app (universal: arm64 + x86_64)
make install    # copy to /Applications and launch
make dist       # create the DMG, ZIP, and SHA256SUMS.txt in dist/
make clean      # remove build output
```

There is no Xcode project. The `Makefile` calls `swiftc` directly.

## Code guidelines

- **Swift 6 language mode with MainActor default isolation.** The `Makefile` passes `-swift-version 6 -default-isolation MainActor`. Notification and timer callbacks are delivered on the main thread, so wrap their bodies in `MainActor.assumeIsolated { … }`.
- **Deployment target is macOS 15.** Wrap any newer API in `#available` and provide a fallback. Current examples: `glassEffect` (macOS 26) in `Overlay.swift`, and `textInputBorderShape` (macOS 27) in `roundedInputBorder()` in `SettingsView.swift`.
- **Don't use `@State`.** In the macOS 27 SDK, SwiftUI's `@State` is a macro, and the Command Line Tools don't include the SwiftUI macro plugin, so it fails to compile there. Use an `ObservableObject` with `@StateObject`, or `@AppStorage`. Keep the code buildable with the Command Line Tools alone.
- **No code comments.** The codebase is intentionally comment-free. Explain non-obvious decisions in commit messages instead.
- **Settings** are stored in `UserDefaults`. Add new keys to `K` and their defaults to `registerDefaults()` in `Prefs.swift`.

## Localization

- UI strings are written in Korean in the source, and the Korean text is the localization key.
- Add every new string to `en.lproj/Localizable.strings` and `ja.lproj/Localizable.strings`. `ko.lproj/Localizable.strings` is empty on purpose: it only tells macOS that Korean is supported.
- Strings with interpolation become format keys, for example `"선택한 앱 (%lld)"`.
- The README exists in English, Korean, Japanese, and Simplified Chinese. When a change affects users, update all four. The app has no Chinese UI, so the Chinese README quotes UI labels in English.

## Release

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. Merge into `main`, then push a tag that matches the version, for example `v1.2.0`.
3. GitHub Actions (`.github/workflows/release.yml`, `xcode-27` runner) checks that the tag matches `Info.plist`, builds the DMG, ZIP, and `SHA256SUMS.txt`, and creates a draft release using `.github/release-notes.md`.
4. Fill in "What's new" on the draft and publish it.

Builds are ad-hoc signed and not notarized. Pull requests run the same build without creating a release.
