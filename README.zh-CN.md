<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 图标"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
无论你用哪种语言输入，都能在 macOS 上始终置顶显示当前输入语言的徽标应用。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <b>简体中文</b>
</p>

如果你经常在多种语言之间切换输入，又整天待在终端、Vim 或其他命令行工具里，一定遇到过这种情况：按下快捷键却毫无反应，这才发现输入法还停在别的语言上。CheatIME 在屏幕上显示一个小徽标，让你一眼看清当前的输入语言；切换到特定应用时，它还能自动帮你切换输入法。

<p align="center"><img src="docs/badges.png" width="560" alt="多种语言和形状的徽标示例"></p>

## 功能

**徽标**
- 始终置顶，在所有空间和全屏应用上方都可见
- 按语言而不是按具体输入法判断，因此适用于任何语言、任何厂商的输入法
- 韩语、日语和英语预设了显示文字和颜色；其他语言在你自定义之前显示语言代码（例如 ZH、RU、AR）
- 可为每种语言设置显示文字、背景色和文字颜色，也可以在特定语言下隐藏徽标
- 可调整形状（圆角矩形、胶囊、圆形、小圆点）、字号（小圆点则为圆点大小）和不透明度，可添加边框（实线、虚线或点线），还可选用 Liquid Glass 效果（macOS 26 及以上）
- 切换输入法时可播放任一 macOS 系统提示音（macOS 本身没有这个选项）

**显示位置**
- 以下三种位置可以任意组合同时开启，例如在屏幕角落固定一个徽标，同时在文本光标旁再显示一个。形状、大小、不透明度、边框和 Liquid Glass 效果可以按位置分别设置。
- Fixed（固定位置）：用 3×3 对齐网格和边距定位，可显示在所有显示器、鼠标指针所在的显示器或你选定的显示器上。也可以直接拖动徽标。
- Next to pointer（鼠标指针旁）：徽标跟随鼠标指针移动。
- Next to text cursor（文本光标旁）：徽标显示在文本光标旁边。需要辅助功能权限（macOS 27 中称为“设备控制和数据访问”）。在无法获取文本光标的应用（例如部分终端）中，可以改为显示在鼠标指针旁（此选项可以关闭）；如果同时开启了 Next to pointer，则不再重复显示。

**应用**
- 仅在勾选的应用位于前台时显示徽标。已勾选的应用排在列表最前面。
- 自动切换规则：某个应用来到前台时，自动切换到你指定的输入法。每条规则都可设置在离开该应用时切回原来的输入法。

**其他**
- 点按徽标即可隐藏，右键点按（或按住 Control 键点按）打开菜单
- Open at login（登录时自动打开）
- 设置窗口和菜单提供英文、韩文和日文界面（暂无中文界面）。这只是应用自身的界面语言，徽标适用于所有语言的输入法
- 不联网，也不读取键盘输入

<p align="center"><img src="docs/settings-en.png" width="560" alt="徽标设置"></p>
<p align="center"><img src="docs/rules-en.png" width="560" alt="自动切换规则"></p>

## 系统要求

macOS 15 Sequoia 及以上，支持搭载 Apple 芯片或 Intel 芯片的 Mac（通用二进制）。

## 安装

1. 从 [Releases](https://github.com/HikiJun97/CheatIME/releases) 下载 `CheatIME-<版本>.dmg`。
2. 打开 DMG，将 **CheatIME** 拖到 **Applications**。
3. CheatIME 未经过 Apple 公证，首次打开时会被 macOS 拦截。请用以下任一方式放行：
   - 先打开一次 CheatIME，被拦截后前往**系统设置 → 隐私与安全性**，在 CheatIME 的提示旁点按**仍要打开**并确认。
   - 或在终端中运行：
     ```sh
     xattr -dr com.apple.quarantine /Applications/CheatIME.app
     ```

如需登录后自动启动 CheatIME，请在 Settings → General 中打开 **Open at login**（登录时打开）。

## 使用方法

- **菜单栏图标**：Settings…（⌘,）、Show Badge、Quit CheatIME
- **徽标**：点按隐藏，拖动调整位置，右键点按打开菜单
- 如果菜单栏图标被刘海遮住，或在系统设置的“菜单栏”中被关闭，可以从 Spotlight 或访达再次打开 CheatIME，这时会弹出 Settings 窗口。

### 辅助功能权限

只有使用 **Next to text cursor**（文本光标旁）时才需要。在 Settings → Position 中开启该位置后，前往**系统设置 → 隐私与安全性 → 辅助功能**（macOS 27 中为**设备控制和数据访问**）允许 CheatIME。

由于 CheatIME 没有使用 Apple Developer ID 签名，macOS 会把每个新版本视为不同的应用。更新后，请先从该列表中移除 CheatIME，再重新允许。

## 从源码构建

需要 Xcode，或包含 macOS 27 SDK 的 Command Line Tools（Swift 6.2 及以上）。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # 构建 CheatIME.app（通用二进制）
make install    # 复制到 /Applications 并启动
make dist       # 在 dist/ 中生成 DMG 和 ZIP
```

## 卸载

退出 CheatIME，删除 `/Applications/CheatIME.app`（或运行 `make uninstall`）。如需同时删除设置，请运行：

```sh
defaults delete io.github.hikijun97.cheatime
```

如果打开过 **Open at login** 或授予过辅助功能权限，也请在系统设置的相应列表中移除 CheatIME。

## 隐私

CheatIME 通过 Text Input Sources API 向 macOS 查询当前使用的输入法，并在符合规则时切换输入法。它不监听键盘输入，也不建立任何网络连接。使用 **Next to text cursor** 时，辅助功能权限仅用于读取文本光标的位置。设置保存在 macOS 标准的用户默认设置（user defaults）中。

## 许可证

[MIT](LICENSE)
