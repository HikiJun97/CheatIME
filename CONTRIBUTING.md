# Contributing to CheatIME

Thanks for your interest in CheatIME. Bug reports, fixes, new features, and translations are all welcome.

## How to contribute

- **Bugs and ideas:** open an issue with one of the templates.
- **Small changes**, such as typos and bug fixes: open a pull request directly.
- **Larger changes**, such as new features, new settings, or refactoring: open an issue first, so we can agree on the approach before you spend time on it.
- **Translations:** see [Translations](#translations).

### Pull requests

1. Fork the repository and create a branch from `main`.
2. Keep each pull request to one change.
3. Write commit messages in English, in the imperative mood: `Add …`, `Fix …`, `Show …`.
4. There are no automated tests. Install your build with `make install`, try the change in the app, and write in the pull request what you checked: your macOS version and the input sources you tried.
5. Open the pull request against `main`. CI builds every pull request, and the build must pass. For first-time contributors, a maintainer approves the CI run first.

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

## Requirements

- Xcode 27, or the Command Line Tools with the macOS 27 SDK (Swift 6.2 or later)
- The macOS 27 SDK is needed only to build. The app targets macOS 15, so the result runs on macOS 15 or later.
- `make dist` also needs [dmgbuild](https://github.com/dmgbuild/dmgbuild) on `PATH` (for example, `uv tool install dmgbuild==1.6.7`). The DMG window layout and background live in `dmg/`.

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
- **Every input language is in scope.** CheatIME aims to work with input sources in any language. `langDefaults()` in `Prefs.swift` presets labels and colors only for Korean, Japanese, and English; every other language must keep working through the fallback (its language code), so don't add logic that assumes a fixed set of languages.
- **Settings** are stored in `UserDefaults`. Declare each setting once in `K` in `Prefs.swift` as a `Pref` that holds its key and default, for example `static let snapToEdges = Pref("snapToEdges", true)`. Read it with `UserDefaults.standard[K.snapToEdges]` and bind it with `@AppStorage(K.snapToEdges) private var snapToEdges: Bool`, so the default is written in one place only. Badge style settings exist once per scope, so they are `StylePref`s that you use through `K.style(scope, K.fontSize)`; using one directly doesn't compile. Use a `String` enum for a setting with a fixed set of values. To rename or remove a key, move the old value in `migrate()`.
- **`K.portable` is a hand-written list on purpose.** Add every setting that settings export and import should carry to it yourself. Don't replace it with reflection (`Mirror`) or other implicit registration: the project prefers plain code that readers can follow and the compiler can check.

## Localization

- UI strings are written in Korean in the source, and the Korean text is the localization key.
- Add every new string to every `Localizable.strings` except Korean's. If you can't write one of the languages, put the English text there and say so in the pull request, so a translator can fill it in later. `ko.lproj/Localizable.strings` is empty on purpose: it only tells macOS that Korean is supported.
- Strings with interpolation become format keys, for example `"선택한 앱 (%lld)"`.
- The README exists in English, Korean, Japanese, and Simplified Chinese. When a change affects users, update at least the English `README.md`. Updating the other languages is welcome but not required; say in the pull request which ones you left out. The app has no Chinese UI, so the Chinese README quotes UI labels in English.

## Translations

CheatIME is about input languages, so docs and UI in more languages are especially welcome. You don't need to know Swift to translate. Send translations as their own pull requests, separate from code changes.

### README

- To fix or improve a translation, edit its `README.<code>.md`.
- To add a language, copy `README.md` to `README.<code>.md`, using a language code like the existing files (`ko`, `ja`, `zh-CN`). Add the language to the links at the top of every README and to the last line of `.github/release-notes.md`.
- If the app has no UI in that language, quote UI labels in English and use the English screenshots (`docs/*-en.png`), as the Chinese README does.

### App

- To fix or improve a translation, edit `<code>.lproj/Localizable.strings`.
- To add a language:
  1. Copy `en.lproj/Localizable.strings` to `<code>.lproj/Localizable.strings` and translate the right-hand side of each line. Keep the Korean keys on the left and format specifiers such as `%lld` and `%@` as they are.
  2. In `General.swift`, add the language code to `AppLanguage.languages`, and add the language, written in its own name, to the language picker.
  3. Run `make install`, choose the language in **Settings → General → Language**, and check that every label fits.

## Release

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. Merge into `main`, then push a tag that matches the version, for example `v1.2.0`.
3. GitHub Actions (`.github/workflows/release.yml`, `xcode-27` runner) checks that the tag matches `Info.plist`, signs the app, builds the DMG, ZIP, and `SHA256SUMS.txt`, and creates a draft release using `.github/release-notes.md`.
4. Fill in "What's new" on the draft and publish it.

Builds are not notarized. Pull requests run the same build, ad-hoc signed, without creating a release.

## Code signing

Releases are signed with a self-signed certificate whose SHA-1 is `SIGN_CERT` in the `Makefile`. macOS ties the Accessibility grant to that certificate, so the grant survives updates. The workflow reads the certificate from the `SIGNING_CERTIFICATE` (base64 p12) and `SIGNING_CERTIFICATE_PASSWORD` secrets and fails if the app is not signed with `SIGN_CERT`.

`make` and `make install` use the same certificate when it is in your keychain, and ad-hoc signing otherwise. macOS treats an ad-hoc build as a new app whenever its code changes, so after installing one you have to remove CheatIME from the Accessibility list and allow it again.

Replace the certificate only if it is lost or leaked, because every user would have to allow Accessibility again. Update `SIGN_CERT` and both secrets together.
