<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 图标"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
在 macOS 上始终置顶显示当前输入语言的徽标应用。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <b>简体中文</b>
</p>

一款始终置顶的输入模式指示器，把当前输入语言一直显示在屏幕上你指定的角落或光标旁。在 nvim 这类终端环境中，不切换到英文输入，快捷键等命令就无法使用；CheatIME 正是为这类场景下的多语言用户而做的。

<p align="center"><img src="docs/badges.png" width="560" alt="多种语言和形状的徽标示例"></p>

## 功能

- 始终显示在所有窗口上方，包括全屏应用
- 指示器可以显示在屏幕上的固定位置、鼠标指针旁或文本光标旁等任意位置（文本光标旁仅支持部分应用）
- 可为每种语言自由设置指示器的样式
- 可以一直显示，也可以只在语言切换时显示
- 可以只在你选择的应用中显示指示器
- 可设置规则：切换到特定应用时，自动切换到特定语言
- 支持提示音

界面提供英文、韩文和日文（暂无中文界面），下文的设置项名称以英文界面为准。

<p align="center"><img src="docs/settings-en.png" width="560" alt="徽标设置"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="自动切换规则"></p>

## 系统要求

macOS 15 及以上，Apple 芯片或 Intel 芯片的 Mac

## 安装

1. 从 [Releases](https://github.com/HikiJun97/CheatIME/releases) 下载 `CheatIME-<版本>.dmg`。
2. 打开 DMG，将 **CheatIME** 拖到 **Applications**。
3. 先打开一次，然后在**系统设置 → 隐私与安全性**中点按**仍要打开**。或者在终端中运行：
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## 注意事项

- 要把指示器显示在 **Next to Text Cursor**（文本光标旁），需要辅助功能权限（macOS 27 中为**设备控制和数据访问**）。请在**系统设置 → 隐私与安全性 → 辅助功能**中允许 CheatIME。

## 从源码构建

需要 macOS 27 SDK（Xcode 或 Command Line Tools）。首次构建时会下载 Sparkle 框架。`make dist` 还需要 [dmgbuild](https://github.com/dmgbuild/dmgbuild)（`uv tool install dmgbuild==1.6.7`）。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # 构建 CheatIME.app
make install    # 复制到 /Applications 并启动
make dist       # 在 dist/ 中生成 DMG 和 ZIP
```

## Inspired by

- [ShowyEdge](https://github.com/pqrs-org/ShowyEdge)
- [Input Source Pro](https://github.com/runjuu/InputSourcePro)

## 许可证

[MIT](LICENSE)

更新功能使用 [Sparkle](https://sparkle-project.org)，其许可证随应用一同提供。
