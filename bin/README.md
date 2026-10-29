# bin/：ツールの置き場所

ここに置くツールは `setup.bat`（`work/setup.ps1`）がダウンロードして展開します。Git で管理しているのは、この README と `npm-tools/package.json`、`npm-tools/package-lock.json` だけです。

| ツール | バージョン | 置き場所 | 用途 |
|---|---|---|---|
| pandoc | 3.12.1（2026-10-08 公開） | `pandoc-3.12.1/` | Markdown → Typst |
| Typst | 0.15.1（2026-07-17 公開） | `typst-0.15.1/` | Typst → PDF |
| @vscode/vsce | 4.0.0 | `npm-tools/` | VS Code 拡張機能を `.vsix` にまとめる |
| markdown-it | 14.3.2 | `npm-tools/` | 拡張機能を VS Code の外で試す（`work/vscode-preview/test/render.js`） |

本文のフォント Noto Serif JP も `setup.bat` が入れますが、置き場所は `source/_fonts/NotoSerifJP/` です。

## 入手元と検証

| ファイル | 入手元 | SHA-256 |
|---|---|---|
| pandoc-3.12.1-windows-x86_64.zip | https://github.com/jgm/pandoc/releases/tag/3.12.1 | `6ef431cb20b2c24a0371fc19200dc49d452be54b1b5c9239f3462841ef53e587` |
| typst-x86_64-pc-windows-msvc.zip | https://github.com/typst/typst/releases/tag/v0.15.1 | `19ce3551153c2fe7ee9fa2f95208310c8f4d3209fedb699e0333faf8913f6736` |
| 12_NotoSerifJP.zip | https://github.com/notofonts/noto-cjk/releases/tag/Serif2.003 | `53bdd2a6e4eb63bf24f7890e018dddb94366e3555d0814c72b74fbb128f328f0` |

`setup.ps1` は、ダウンロードしたファイルの SHA-256 を上の値と照合します。一致しなければ、展開せずに止まります。

上の値をどう確かめたかは、ファイルごとに違います。

| ファイル | 確かめ方 |
|---|---|
| pandoc | GitHub Releases の API がファイルごとに返すハッシュ（`digest`）と照合して決めた |
| Typst | 同上 |
| Noto Serif JP | API がハッシュを返さない古いリリースなので、2026-10-29 にダウンロードしたファイルのハッシュをそのまま固定した |

ハッシュ以外の検証は次のとおりです。

- **pandoc.exe**: SignPath Foundation による Authenticode 署名が付いています。`setup.ps1` は、展開したあとに署名の状態を表示します。`Valid` でなければ警告を出します。
- **Typst**: 作者による署名はありません。確かめられるのは、GitHub のリリースのファイルと同じであることだけです。
- **npm パッケージ**:
  - `npm ci --ignore-scripts` で、`package-lock.json` に記録された版とハッシュ（sha512）のとおりに入れます。パッケージ側のインストールスクリプトは実行しません。
  - 入れたあと、`npm audit signatures` で npm レジストリの署名を確かめます。
  - 2026-10-29 の時点では、124 パッケージすべてでレジストリの署名を確認できました。そのうち 6 パッケージは provenance も確認できました。
  - @vscode/vsce と markdown-it には provenance がありません。

## 版を上げるとき

1. `work/setup.ps1` の `$Packages` にある URL と SHA-256 を書き換えます。
2. 置き場所のフォルダ名に版が入っている場合は、`work/md2pdf.ps1` のパスも書き換えます。
3. この README も書き換えます。
4. `setup.bat -Force` を実行します。
