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

```bat
cd /d D:\_claude\md2pdf\work\vscode-preview
..\..\bin\npm-tools\node_modules\.bin\vsce package --skip-license --allow-missing-repository -o md2pdf-preview.vsix
code --install-extension md2pdf-preview.vsix --force
```

インストールしたあと、開いているプレビューを一度閉じて開き直すと反映される（または VS Code を再読み込みする）。

`work/vscode-preview/test/render.js` で、VS Code を使わずにテスト用の md を HTML に変換して確認できる。
