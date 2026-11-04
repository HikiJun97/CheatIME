<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME icon"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
An always-on-top badge that shows your current input language (한 / EN / あ) on macOS.<br>
<b>English</b> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

If you type in more than one language and spend your day in a terminal, Vim, or other CLI tools, you know the pain: you press a shortcut, nothing happens, and only then do you notice the input source is still set to Korean, Japanese, or Chinese. CheatIME puts a small badge on screen so you can tell your input language at a glance, and it can switch the input source for you when you move to a particular app.

<p align="center"><img src="docs/badges.png" width="480" alt="Badge shapes"></p>

## Features

**Badge**
- Always on top, on every Space and over full-screen apps
- Works with any input method (Apple, Gureum, Kotoeri, and others) because it detects the language, not the input method
- Per-language label, background color, and text color, plus an option to hide the badge for specific languages
- Shapes: rounded rectangle, capsule, circle, or a minimal dot; font size, opacity, and an optional Liquid Glass look (macOS 26 or later)
- Optional sound when the input source changes, using any of the macOS system sounds (macOS has no built-in option for this)

**Placement**
- Fixed: a 3×3 alignment grid with margins, on all displays, the display with the pointer, or displays you pick. You can also just drag the badge.
- Next to the pointer: the badge follows the mouse pointer.
- Next to the text cursor: the badge sits beside the text cursor. This needs Accessibility access. In apps that don't report a text cursor (some terminals, for example), it falls back to the pointer.

**Apps**
- Show the badge only when one of the apps you check is in front. Checked apps are listed first.
- Auto-switch rules: when an app comes to the front, switch to the input source you choose. Each rule can switch back to the previous input source when you leave the app.

**Everything else**
- Click the badge to hide it; right-click (or Control-click) to open the menu
- Open at login
- Interface in English, Korean, and Japanese
- No network access, and it never reads your keystrokes

<p align="center"><img src="docs/settings-en.png" width="560" alt="Badge settings"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="Auto-switch rules"></p>

## Requirements

macOS 15 Sequoia or later, on Apple silicon or Intel (universal binary).

## Install

1. Download `CheatIME-<version>.zip` from [Releases](https://github.com/HikiJun97/CheatIME/releases).
2. Unzip it and move `CheatIME.app` to `/Applications`.
3. CheatIME is not notarized by Apple, so macOS blocks the first launch. Allow it in one of these ways:
   - Open CheatIME once. After macOS blocks it, go to **System Settings → Privacy & Security**, click **Open Anyway** next to the CheatIME message, and confirm.
   - Or run this in Terminal:
     ```sh
     xattr -dr com.apple.quarantine /Applications/CheatIME.app
     ```

To start CheatIME automatically, turn on **Open at login** in Settings → General.

## Usage

- **Menu bar icon**: Settings… (⌘,), Show Badge, Quit
- **Badge**: click to hide, drag to move, right-click for the menu
- If the menu bar icon is hidden (behind the notch, or turned off in **Allow in the Menu Bar**), open CheatIME again from Spotlight or Finder to bring up Settings.

### Accessibility access

Only the **Next to the text cursor** placement needs it. Choose it in Settings → Position, then allow CheatIME in **System Settings → Privacy & Security → Accessibility**.

Because CheatIME is not signed with an Apple Developer ID, macOS treats every new version as a different app. After you update, remove CheatIME from the Accessibility list and allow it again.

## Build from source

Requires Xcode or the Command Line Tools with the macOS 27 SDK (Swift 6.2 or later).

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # build CheatIME.app (universal)
make install    # copy to /Applications and launch
make dist       # create CheatIME-<version>.zip
```

## Uninstall

Quit CheatIME, delete `/Applications/CheatIME.app` (or run `make uninstall`), and optionally remove its settings:

```sh
defaults delete io.github.hikijun97.cheatime
```

If you turned on **Open at login** or granted Accessibility access, remove CheatIME from those lists in System Settings as well.

## Privacy

CheatIME asks macOS which input source is active and switches it when one of your rules applies, using the Text Input Sources API. It does not monitor keystrokes and makes no network connections. With **Next to the text cursor**, it uses Accessibility access only to read where the text cursor is. Settings are stored in the standard user defaults.

## License

[MIT](LICENSE)
