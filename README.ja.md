<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME アイコン"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
現在の入力言語（한 / EN / あ）を macOS の画面の隅に常に表示するバッジアプリです。<br>
<a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <b>日本語</b> · <a href="README.zh-CN.md">简体中文</a>
</p>

複数の言語で入力しながら、ターミナルや Vim、CLI ツールを使うことが多い人なら、こんな経験があるはずです。ショートカットを押しても反応がなく、そこで初めて入力ソースが日本語のままだったと気づく。CheatIME は画面の隅に小さなバッジを表示し、今の入力言語をひと目で分かるようにします。

<p align="center"><img src="docs/badges.png" width="420" alt="バッジの形"></p>

## 機能

- すべての操作スペースとフルスクリーンアプリの上にも常に表示されるバッジ
- 入力メソッドではなく言語で判別するため、Apple 標準、ことえり、Gureum など、どの入力メソッドでも使えます
- 言語ごとに表示文字、背景色、文字色を設定でき、特定の言語ではバッジを隠すこともできます
- 表示するディスプレイを選択：すべてのディスプレイ、ポインタがあるディスプレイ、選んだディスプレイ
- 形（角丸、カプセル、円）、文字サイズ、不透明度、Liquid Glass 効果（macOS 26 以降）
- 3×3 の配置と余白で位置を決めるか、バッジをドラッグして移動
- バッジをクリックすると非表示、右クリック（または Control+クリック）でメニュー
- 日本語、英語、韓国語の画面に対応
- 権限不要、ネットワーク通信なし、キー入力を読み取りません

<p align="center"><img src="docs/settings-ja.png" width="560" alt="設定ウインドウ"></p>

## 動作環境

macOS 15 Sequoia 以降、Apple シリコンと Intel Mac の両方に対応（ユニバーサルバイナリ）。

## インストール

1. [Releases](https://github.com/HikiJun97/CheatIME/releases) から `CheatIME-<バージョン>.zip` をダウンロードします。
2. 解凍して `CheatIME.app` を `/Applications` に移動します。
3. CheatIME は Apple の公証を受けていないため、初回起動時に macOS がブロックします。次のどちらかの方法で許可してください。
   - CheatIME を一度開き、ブロックされたら **システム設定 → プライバシーとセキュリティ** を開き、CheatIME のメッセージの横にある **このまま開く** をクリックして確認します。
   - またはターミナルで次のコマンドを実行します。
     ```sh
     xattr -dr com.apple.quarantine /Applications/CheatIME.app
     ```

ログイン時に自動で起動するには、**システム設定 → 一般 → ログイン項目** に CheatIME を追加してください。

## 使い方

- **メニューバーアイコン**：設定…（⌘,）、バッジを表示、終了
- **バッジ**：クリックで非表示、ドラッグで移動、右クリックでメニュー
- メニューバーアイコンがノッチに隠れている場合や、システム設定のメニューバー項目でオフになっている場合は、Spotlight や Finder から CheatIME をもう一度開くと設定ウインドウが開きます。

## ソースからビルド

Xcode、または macOS 27 SDK を含む Command Line Tools（Swift 6.2 以降）が必要です。

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # CheatIME.app をビルド（ユニバーサル）
make install    # /Applications にコピーして起動
make dist       # CheatIME-<バージョン>.zip を作成
```

## アンインストール

CheatIME を終了し、`/Applications/CheatIME.app` を削除します（`make uninstall` でも可）。設定も削除する場合は次を実行します。

```sh
defaults delete io.github.hikijun97.cheatime
```

## プライバシー

CheatIME は Text Input Sources API を使って、どの入力ソースが選択されているかを macOS に問い合わせるだけです。キー入力を監視せず、アクセシビリティや入力監視の権限も不要で、ネットワークにも接続しません。設定は macOS 標準のユーザデフォルトに保存されます。

## ライセンス

[MIT](LICENSE)
