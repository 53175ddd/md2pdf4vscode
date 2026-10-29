# md2pdf Preview（VS Code 拡張機能）

VS Code 標準の Markdown プレビューを、md2pdf が出力する PDF に近い見た目にする拡張機能。

| 書き方 | プレビューでの表示 | PDF 側の対応 |
|---|---|---|
| `:icon_名前:` | 一番近い上位フォルダの `_icons/icon_名前.(svg/png/…)` を文字の高さで表示 | `work/icons.lua` |
| `[文字]{color=red}` | 文字色（Typst と同じ色の値） | `work/color.lua` |
| `<!-- origin: N -->` | `##`〜`####` に `N.` / `N-1.` / `N-1-1.` を付ける | `work/numbering.lua` |
| `<!-- pagebreak -->` | 「改ページ」と書いた破線 | `work/pagebreak.lua` |
| 単独の段落の画像 | ドロップシャドー | `work/shadow.lua` |
| インラインコード | 背景・枠・文字色 | `work/style.typ` |
| 日本語どうしの間の改行 | 空白を入れずにつなげる | `east_asian_line_breaks` |

## ビルドとインストール

リポジトリ直下の `setup.bat` が、ビルドとインストールまで行う（Node.js と VS Code の `code` コマンドが必要）。手で行う場合は、`setup.bat` を一度実行して `bin\npm-tools\` を用意したあと、リポジトリ直下で次を実行する。

```bat
cd work\vscode-preview
..\..\bin\npm-tools\node_modules\.bin\vsce package --skip-license --allow-missing-repository -o md2pdf-preview.vsix
code --install-extension md2pdf-preview.vsix --force
```

インストールしたあと、開いているプレビューを一度閉じて開き直すと反映される（または VS Code を再読み込みする）。

## テスト

VS Code を使わずに、テスト用の md を HTML に変換して確認できる（リポジトリ直下で実行）。

```bat
node work\vscode-preview\test\render.js work\vscode-preview\test\edge.md %TEMP%\edge.html source\edge.md
```

3 つ目の引数は、プレビューが「開いている文書」とみなす場所。アイコンはそこから上のフォルダへたどって、最初に見つかった `_icons` から探す。
