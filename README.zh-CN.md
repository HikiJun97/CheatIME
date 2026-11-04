<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 图标"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
在 macOS 屏幕上始终显示当前输入语言（한 / EN / あ）的徽标应用。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <b>简体中文</b>
</p>

如果你经常在多种语言之间切换输入，又整天待在终端、Vim 或其他命令行工具里，一定遇到过这种情况：按下快捷键却毫无反应，这才发现输入法还停留在中文。CheatIME 在屏幕上显示一个小徽标，让你一眼看清当前的输入语言；切换到特定应用时，它还能替你切换输入法。

<p align="center"><img src="docs/badges.png" width="480" alt="徽标形状"></p>

## 功能

**徽标**
- 始终置顶，在所有桌面空间和全屏应用上方都可见
- 按语言而不是按输入法判断，因此适用于任何输入法（Apple 自带输入法、Gureum、日文输入法等）
- 可为每种语言设置显示文字、背景色和文字颜色，也可以在特定语言下隐藏徽标
- 形状（圆角矩形、胶囊、圆形、小圆点）、字号、不透明度，以及可选的 Liquid Glass 效果（macOS 26 及以上）
- 可选在输入法切换时播放 macOS 系统提示音（macOS 本身没有这个选项）

**显示位置**
- 固定位置：通过 3×3 对齐和边距确定位置，可选择所有显示器、鼠标指针所在的显示器或手动选择的显示器。也可以直接拖动徽标。
- 鼠标指针旁：徽标跟随鼠标指针移动。
- 文本光标旁：徽标显示在输入光标旁边。需要辅助功能权限。在无法提供光标位置的应用（例如部分终端）中，会改为显示在鼠标指针旁。

**应用**
- 仅当勾选的应用位于最前方时显示徽标。勾选的应用会集中列在最上方。
- 自动切换规则：某个应用切换到前台时，自动切换到你选择的输入法。每条规则都可以设置在离开该应用时切回之前的输入法。

**其他**
- 点击徽标将其隐藏，右键（或按住 Control 点按）打开菜单
- 登录时自动打开
- 界面支持英文、韩文和日文（暂不支持中文界面）
- 不联网，不读取键盘输入

<p align="center"><img src="docs/settings-en.png" width="560" alt="徽标设置"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="自动切换规则"></p>

## 系统要求

macOS 15 Sequoia 及以上，支持 Apple 芯片和 Intel 芯片的 Mac（通用二进制）。

## 安装

1. 从 [Releases](https://github.com/HikiJun97/CheatIME/releases) 下载 `CheatIME-<版本>.zip`。
2. 解压后将 `CheatIME.app` 移到 `/Applications`。
3. CheatIME 未经过 Apple 公证，首次打开时会被 macOS 拦截。请用以下任一方式放行：
   - 先打开一次 CheatIME，被拦截后前往 **系统设置 → 隐私与安全性**，在 CheatIME 的提示旁点按 **仍要打开** 并确认。
   - 或在终端中运行：
     ```sh
     xattr -dr com.apple.quarantine /Applications/CheatIME.app
     ```

如需登录时自动启动，请在 设置 → 通用 中打开 **登录时打开**。

## 使用方法

- **菜单栏图标**：设置…（⌘,）、显示徽标、退出
- **徽标**：点击隐藏，拖动移动，右键打开菜单
- 如果菜单栏图标被刘海遮住，或在系统设置的菜单栏选项中被关闭，可以从 Spotlight 或访达再次打开 CheatIME，这时会弹出设置窗口。

### 辅助功能权限

只有使用 **文本光标旁** 时才需要。在 设置 → 显示位置 中选择该方式后，前往 **系统设置 → 隐私与安全性 → 辅助功能** 允许 CheatIME。

由于 CheatIME 没有使用 Apple Developer ID 签名，macOS 会把每个新版本当作不同的应用。更新后，请先从辅助功能列表中移除 CheatIME，再重新允许。

## 从源码构建

需要 Xcode，或包含 macOS 27 SDK 的 Command Line Tools（Swift 6.2 及以上）。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # 构建 CheatIME.app（通用二进制）
make install    # 复制到 /Applications 并启动
make dist       # 生成 CheatIME-<版本>.zip
```

## 卸载

退出 CheatIME，删除 `/Applications/CheatIME.app`（也可以运行 `make uninstall`）。如需同时删除设置，请运行：

```sh
defaults delete io.github.hikijun97.cheatime
```

如果打开过 **登录时打开** 或授予过辅助功能权限，也请在系统设置的相应列表中移除 CheatIME。

## 隐私

CheatIME 通过 Text Input Sources API 向 macOS 查询当前选中的输入法，并在符合规则时切换输入法。它不监听键盘输入，也不会进行任何网络连接。使用 **文本光标旁** 时，辅助功能权限仅用于读取文本光标的位置。设置保存在 macOS 标准的用户默认设置（user defaults）中。

## 许可证

[MIT](LICENSE)
