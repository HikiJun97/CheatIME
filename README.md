<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME icon"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
An always-on-top badge that shows your current input language on macOS.<br>
<b>English</b> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

Ever pressed a shortcut in the terminal or Vim, only to find the input source was set to another language? CheatIME shows your input language at a glance and can switch it for you in specific apps.

<p align="center"><img src="docs/badges.png" width="560" alt="Example badges for several languages and shapes"></p>

## Features

- Stays on top of everything, including full-screen apps
- Works with input sources in any language
- Place the badge at a fixed spot, next to the pointer, or next to the text cursor, or several at once
- Set the label and colors for each language, plus shape, size, opacity, border, and Liquid Glass
- Show it all the time, or only briefly when the input source changes
- Show it only in the apps you choose
- Switch to a chosen input source automatically when an app comes to the front
- Optional sound on change, and Open at login
- Updates itself from within the app; it asks on the second launch whether to check automatically

<p align="center"><img src="docs/settings-en.png" width="560" alt="Badge settings"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="Auto-switch rules"></p>

## Requirements

macOS 15 or later, Apple silicon or Intel.

## Install

1. Download `CheatIME-<version>.dmg` from [Releases](https://github.com/HikiJun97/CheatIME/releases).
2. Open the DMG and drag **CheatIME** to **Applications**.
3. CheatIME isn't notarized, so macOS blocks the first launch. Open it once, then click **Open Anyway** in **System Settings → Privacy & Security**. Or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## Usage

- **Menu bar icon**: Settings… (⌘,), Show Badge, Check for Updates…, Quit CheatIME
- **Badge**: click to hide, drag to move, right-click for the menu
- Can't see the menu bar icon? Open CheatIME again from Spotlight or Finder to bring up Settings.

**Next to Text Cursor** needs Accessibility access (**Device Control and Data Access** in macOS 27). Allow CheatIME in **System Settings → Privacy & Security → Accessibility**. If you update from 1.2.0 or earlier, remove CheatIME from that list and allow it again once.

## Build from source

Requires the macOS 27 SDK (Xcode or the Command Line Tools). The first build downloads the Sparkle framework.

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # build CheatIME.app
make install    # copy to /Applications and launch
make dist       # create the DMG and ZIP in dist/
```

## Uninstall

Quit CheatIME and delete it from Applications (or run `make uninstall`). To remove its settings too:

```sh
defaults delete io.github.hikijun97.cheatime
```

## Privacy

CheatIME doesn't read your keystrokes. It connects to GitHub only to check for updates, which you can turn off in Settings → General. Accessibility access is used only to find the text cursor.

## Inspired by

- [ShowyEdge](https://github.com/pqrs-org/ShowyEdge)
- [Input Source Pro](https://github.com/runjuu/InputSourcePro)

## License

[MIT](LICENSE)

Updates use [Sparkle](https://sparkle-project.org); its license is included in the app.
