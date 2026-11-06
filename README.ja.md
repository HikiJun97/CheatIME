<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME アイコン"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
現在の入力言語を macOS の画面に常に表示するバッジアプリです。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <b>日本語</b> · <a href="README.zh-CN.md">简体中文</a>
</p>

入力言語を画面の好きな隅やカーソルの横に常に表示する、always-on-top 型の入力モードインジケーターです。英語入力でないとショートカットなどのコマンドが効かない nvim のようなターミナル環境で、多言語ユーザーを支えるために作りました。

<p align="center"><img src="docs/badges.png" width="560" alt="さまざまな言語と形のバッジの例"></p>

## 機能

- フルスクリーンアプリを含め、すべてのウインドウより上に表示されます。
- インジケーターは画面上の決まった位置、ポインタの横、テキストカーソルの横など、好きな場所に表示できます。（テキストカーソルは一部のアプリのみ）
- 言語ごとにインジケーターのスタイルを自由に設定できます。
- 常に表示するか、言語が切り替わったときだけ表示するかを選べます。
- 選んだアプリでだけインジケーターを表示できます。
- 特定のアプリに切り替えたときに、特定の言語へ自動で切り替わるようルールを設定できます。
- サウンドで知らせることもできます。

<p align="center"><img src="docs/settings-ja.png" width="560" alt="バッジの設定"></p>
<p align="center"><img src="docs/rules-ja.png" width="560" alt="自動切り替えルール"></p>

## 動作環境

macOS 15 以降、Apple シリコンまたは Intel Mac

## インストール

1. [Releases](https://github.com/HikiJun97/CheatIME/releases) から `CheatIME-<バージョン>.dmg` をダウンロードします。
2. DMG を開き、**CheatIME**を**Applications**にドラッグします。
3. 一度開いてから、**システム設定 → プライバシーとセキュリティ**で**このまま開く**をクリックしてください。またはターミナルで次のコマンドを実行します。
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## 注意事項

- **テキストカーソルの横**にインジケーターを表示するには、アクセシビリティへのアクセス許可（macOS 27 では**デバイスの制御とデータへのアクセス**）が必要です。**システム設定 → プライバシーとセキュリティ → アクセシビリティ**で CheatIME を許可してください。

## ソースからビルド

macOS 27 SDK（Xcode または Command Line Tools）が必要です。初回のビルド時に Sparkle フレームワークをダウンロードします。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # CheatIME.app をビルド
make install    # /Applications にコピーして起動
make dist       # dist/ に DMG と ZIP を作成
```

## Inspired by

- [ShowyEdge](https://github.com/pqrs-org/ShowyEdge)
- [Input Source Pro](https://github.com/runjuu/InputSourcePro)

## ライセンス

[MIT](LICENSE)

アップデートには [Sparkle](https://sparkle-project.org) を使っています。Sparkle のライセンスはアプリに同梱しています。
