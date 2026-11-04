<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME アイコン"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
現在の入力言語を macOS の画面に常に表示するバッジアプリです。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <b>日本語</b> · <a href="README.zh-CN.md">简体中文</a>
</p>

ターミナルや Vim でショートカットを押したら、入力ソースが日本語のままだった。そんなとき、CheatIME なら今の入力言語がひと目で分かります。アプリごとに入力ソースを自動で切り替えることもできます。

<p align="center"><img src="docs/badges.png" width="560" alt="さまざまな言語と形のバッジの例"></p>

## 機能

- フルスクリーンアプリを含め、すべてのウインドウの上に表示されます。
- どの言語の入力ソースでも使えます。
- バッジは画面の決まった位置、ポインタの横、テキストカーソルの横に表示でき、複数の場所に同時に表示することもできます。
- 言語ごとに表示文字と色を設定でき、形、サイズ、不透明度、枠線、ガラス効果（Liquid Glass）も選べます。
- 常に表示するか、入力ソースが切り替わったときだけ一時的に表示するかを選べます。
- 選んだアプリでだけバッジを表示できます。
- アプリが最前面になったら、指定した入力ソースに自動で切り替えます。
- 切り替え時にサウンドを鳴らしたり、ログイン時に自動で起動したりできます。

<p align="center"><img src="docs/settings-ja.png" width="560" alt="バッジの設定"></p>
<p align="center"><img src="docs/rules-ja.png" width="560" alt="自動切り替えルール"></p>

## 動作環境

macOS 15 以降、Apple シリコンまたは Intel Mac

## インストール

1. [Releases](https://github.com/HikiJun97/CheatIME/releases) から `CheatIME-<バージョン>.dmg` をダウンロードします。
2. DMG を開き、**CheatIME**を**Applications**にドラッグします。
3. CheatIME は Apple の公証を受けていないため、初回起動時に macOS にブロックされます。一度開いてから、**システム設定 → プライバシーとセキュリティ**で**このまま開く**をクリックしてください。ターミナルで次のコマンドを実行しても構いません。
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## 使い方

- **メニューバーアイコン**：設定…（⌘,）、バッジを表示、CheatIME を終了
- **バッジ**：クリックで非表示、ドラッグで移動、右クリックでメニューを表示
- メニューバーアイコンが見当たらないときは、Spotlight や Finder から CheatIME をもう一度開くと設定ウインドウが表示されます。

**テキストカーソルの横**に表示するには、アクセシビリティへのアクセス許可（macOS 27 では**デバイスの制御とデータへのアクセス**）が必要です。**システム設定 → プライバシーとセキュリティ → アクセシビリティ**で CheatIME を許可してください。アップデートのたびに、このリストから CheatIME を削除して許可し直す必要があります。

## ソースからビルド

macOS 27 SDK（Xcode または Command Line Tools）が必要です。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # CheatIME.app をビルド
make install    # /Applications にコピーして起動
make dist       # dist/ に DMG と ZIP を作成
```

## アンインストール

CheatIME を終了し、アプリケーションフォルダから削除します（`make uninstall` でも削除できます）。設定も消す場合は、次のコマンドを実行します。

```sh
defaults delete io.github.hikijun97.cheatime
```

## プライバシー

CheatIME はキー入力を読み取らず、ネットワークにも接続しません。アクセシビリティへのアクセスは、テキストカーソルの位置を調べるためだけに使います。

## ライセンス

[MIT](LICENSE)
