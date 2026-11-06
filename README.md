<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME icon"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
An always-on-top badge that shows your current input language on macOS.<br>
<b>English</b> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

An always-on-top input mode indicator that keeps your input language on screen, in a corner of your choice or next to the cursor. It was made for multilingual users of terminal tools like nvim, where shortcuts and other commands only work with English input.

<p align="center"><img src="docs/badges.png" width="560" alt="Example badges for several languages and shapes"></p>

## Features

- Stays on top of every window, including full-screen apps
- Shows the indicator wherever you like: a fixed spot on screen, next to the pointer, or next to the text cursor (text cursor in some apps only)
- Style the indicator however you like for each language
- Show it all the time, or only when the language changes
- Show the indicator only in the apps you choose
- Set rules that switch to a specific language when you switch to a specific app
- Sound alerts

<p align="center"><img src="docs/settings-en.png" width="560" alt="Badge settings"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="Auto-switch rules"></p>

## Requirements

macOS 15 or later, Apple silicon or Intel.

## Install

1. Download `CheatIME-<version>.dmg` from [Releases](https://github.com/HikiJun97/CheatIME/releases).
2. Open the DMG and drag **CheatIME** to **Applications**.
3. Open it once, then click **Open Anyway** in **System Settings → Privacy & Security**. Or run this in Terminal:
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## Notes

- Showing the indicator **Next to Text Cursor** needs Accessibility access (**Device Control and Data Access** in macOS 27). Allow CheatIME in **System Settings → Privacy & Security → Accessibility**.

## Build from source

Requires the macOS 27 SDK (Xcode or the Command Line Tools). The first build downloads the Sparkle framework.

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # build CheatIME.app
make install    # copy to /Applications and launch
make dist       # create the DMG and ZIP in dist/
```

## Inspired by

- [ShowyEdge](https://github.com/pqrs-org/ShowyEdge)
- [Input Source Pro](https://github.com/runjuu/InputSourcePro)

## License

[MIT](LICENSE)

Updates use [Sparkle](https://sparkle-project.org); its license is included in the app.
