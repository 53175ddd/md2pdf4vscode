# md2pdf4vscode

Markdown を PDF に変換する、Windows 用の環境です。日本語の文書を想定しています。
変換には [pandoc](https://pandoc.org/) と [Typst](https://typst.app/) を使います。
VS Code の拡張機能も付いていて、編集中のプレビューを PDF に近い見た目で表示できます。

`source/` に置いた Markdown を、同じフォルダ構成のまま `output/` に PDF として書き出します。

```
source/sample.md          → output/sample.pdf
source/hoge/fuga/piyo.md  → output/hoge/fuga/piyo.pdf
```

## 必要なもの

| 必要なもの | 用途 | なくても動くか |
|---|---|---|
| Windows 10 / 11（64 bit） | PowerShell 5.1 でスクリプトを動かします | 必須 |
| インターネット接続 | セットアップのときだけ使います | 必須 |
| [Node.js](https://nodejs.org/)（npm） | VS Code 拡張機能のビルド | なければ、拡張機能の導入だけを飛ばします |
| [VS Code](https://code.visualstudio.com/)（`code` コマンド） | プレビュー | なければ、拡張機能の導入だけを飛ばします |

## セットアップ

1. このリポジトリを clone するか、ZIP でダウンロードして展開します。
   フォルダの場所は自由ですが、パスに日本語が入らない場所をおすすめします。
2. `setup.bat` をダブルクリックで実行します。

`setup.bat` が行うことは次のとおりです。

| 手順 | 内容 | 置き場所 |
|---|---|---|
| 1 | pandoc 3.12.1 をダウンロードする | `bin/pandoc-3.12.1/` |
| 2 | Typst 0.15.1 をダウンロードする | `bin/typst-0.15.1/` |
| 3 | 本文用のフォント Noto Serif JP 2.003 をダウンロードする | `source/_fonts/NotoSerifJP/` |
| 4 | pandoc.exe のコード署名と、各ツールの版を表示する | — |
| 5 | VS Code 拡張機能をビルドしてインストールする | `bin/npm-tools/`、`work/vscode-preview/md2pdf-preview.vsix` |

- 1〜3 はどれも版を固定してあり、展開する前にファイルの SHA-256 を照合します。値が合わなければ、そこで止まります。
  入手元と検証方法は [bin/README.md](bin/README.md) に書いてあります。
- 5 では、`package-lock.json` に書かれた版のとおりに npm パッケージを入れます（`npm ci --ignore-scripts`）。
  入れたあと `npm audit signatures` で署名を確かめます。
- すでに入っているものはダウンロードしません。

コマンドプロンプトから実行する場合は、次のオプションが使えます。

```bat
setup.bat -NoExtension
```

```bat
setup.bat -Force
```

- `-NoExtension`: VS Code 拡張機能を入れない
- `-Force`: すでに入っているものも、ダウンロードからやり直す

## 使い方

1. 変換したい Markdown を `source/` の下に置きます。サブフォルダに分けてもかまいません。
2. `run.bat` を実行すると、`output/` に PDF ができます。

- `source/` 直下の `_` で始まるフォルダとファイル（`_icons/`、`_fonts/` など）は、素材の置き場所として扱います。この中の Markdown は変換しません。下書きを置いておきたいときは、`source/_draft/` などを使ってください。
- 画像は Markdown からの相対パスで指定します（例: `![](img/window.svg)`）。`source/` の外にある画像は読み込めません。
- まずは [source/sample.md](source/sample.md) を変換して、どのように出力されるかを見てみてください。

## Markdown の書き方

GitHub の Markdown（GFM）に加えて、次の書き方が使えます。

| 書き方 | 結果 |
|---|---|
| `[文字]{color=red}` | 文字色を変える。色は名前（`red`、`blue`、`green`、`orange` など）か `#c00000` の形で指定する |
| `<!-- pagebreak -->`（1 行で書く） | 改ページ |
| `:icon_名前:` | `source/_icons/icon_名前.svg`（または png / jpg / gif / webp）を、文字と同じ高さで入れる。`:icon_a::icon_b:` と詰めて書けば隙間なく並び、`:icon_a: :icon_b:` と空白を入れれば間が空く |
| `<!-- origin: 1 -->` | その文書の `##`〜`####` に章番号を自動で付ける（`1.`、`1-1.`、`1-1-1.`）。数字は最初の `##` の番号 |
| `` `コード` `` | 枠と背景の付いた等幅の文字になる |
| 段落に画像を 1 つだけ置く | 画像に影が付く |

- 日本語の文を途中で改行しても、PDF では空白が入らずにつながります。
- 用紙サイズ（A4）や余白は `work/defaults.yaml` で、インラインコードと影の見た目は `work/style.typ` で変えられます。

## アイコンを追加する

アイコン画像はリポジトリに含めていません（テスト用の `icon_test_red.svg` と `icon_test_blue.svg` だけを入れてあります）。
使いたい画像を自分で用意して、`source/_icons/` に `icon_名前.svg` などの名前で置いてください。
そうすると、本文で `:icon_名前:` と書けるようになります。

- 使える形式は svg / png / jpg / jpeg / gif / webp です。同じ名前のファイルが複数あるときは、この順で最初に見つかったものを使います。
- 名前に使える文字は、英数字と `_`、`-` です。
- 製品やサービスのロゴは、たいてい商標です。配布元の利用条件（社内の資料だけで使ってよい、など）を確認してから使ってください。

## 別のフォントを使う

本文のフォントは、標準では Noto Serif JP です。`setup.bat` が `source/_fonts/NotoSerifJP/` に入れます。
コードには、Windows に最初から入っている Consolas と BIZ UDGothic を使います。

フォントを変えるときは、次の手順で行います。

1. **フォントのファイルを置く。**
   `.ttf`、`.otf`、`.ttc` を `source/_fonts/` に置きます。フォントごとにサブフォルダを作ってもかまいません。
   Windows にインストール済みのフォントを使う場合は、この手順は要りません。
2. **フォントの名前を調べる。**
   変換で指定するのは、ファイル名ではなくフォントファミリーの名前です。次のコマンドを、このリポジトリのフォルダで実行すると、使えるフォントの名前が一覧で出ます。
   ```bat
   bin\typst-0.15.1\typst.exe fonts --font-path source\_fonts
   ```
3. **`work/defaults.yaml` を書き換える。**
   ```yaml
   variables:
     # 本文。指定できるのは 1 つだけ
     mainfont: BIZ UDPMincho
     # コード。上から順に、文字が見つかったフォントを使う
     codefont:
       - Consolas
       - BIZ UDGothic
   ```
4. **`run.bat` で変換し直す。**

注意点:

- `mainfont` に書けるフォントは 1 つだけです。そのフォントにない文字は、Typst がほかのフォントで補います。
- 指定した名前のフォントが見つからなくても、変換は止まりません。Typst が警告を出し、別のフォントで出力します。警告が出ていないか確かめてください。
- `codefont` の先頭は、英数字用のフォントにしてください。日本語フォントの多くは `\` を `¥` の形で表示するので、Windows のパスが読みにくくなります。
- `source/_fonts/` の中身は Git の管理から外してあります（`.gitignore`）。フォントによって再配布の条件が違うためです。
- Noto Serif JP を使わない場合は、`source/_fonts/NotoSerifJP/` を消してもかまいません。ただし、`setup.bat` を実行し直すと、もう一度入ります。
- VS Code のプレビューのフォントは、この設定では変わりません。

## VS Code 拡張機能（md2pdf Preview）

`setup.bat` で入る拡張機能は、VS Code 標準の Markdown プレビューに次の表示を加えます。

- 文字色
- アイコン
- 章番号
- 改ページの位置（破線）
- インラインコードの枠
- 画像の影

詳しくは [work/vscode-preview/README.md](work/vscode-preview/README.md) を見てください。

- インストールしたあと、開いているプレビューを一度閉じて開き直すと反映されます。VS Code の再読み込みでもかまいません。
- Node.js がない環境では、別の PC でビルドした `work/vscode-preview/md2pdf-preview.vsix` をインストールすることもできます。VS Code の拡張機能ビューで「…」→「VSIX からのインストール」を選んでください。
- 変換側の処理（`work/*.lua`、`work/style.typ`）を変えたときは、拡張機能の `md2pdf-plugin.js` と `preview.css` も合わせて直し、`setup.bat` を実行し直してください。拡張機能だけを作り直します。

## フォルダ構成

```
md2pdf4vscode/
├─ LICENSE                  MIT License
├─ setup.bat                ツールとフォントのセットアップ
├─ run.bat                  変換（source/ → output/）
├─ bin/                     ツール（setup.bat が入れる。README.md 以外は Git の管理外）
├─ source/                  変換する Markdown
│  ├─ sample.md             デモ用の文書
│  ├─ img/                  デモ用の画像
│  ├─ _icons/               :icon_名前: の画像
│  └─ _fonts/               変換で使うフォント（Git の管理外）
├─ output/                  出力した PDF（Git の管理外）
└─ work/
   ├─ setup.ps1, md2pdf.ps1 セットアップと変換の本体
   ├─ defaults.yaml         pandoc の設定（フォント、用紙、余白、フィルタ）
   ├─ *.lua                 独自の書き方を処理する pandoc フィルタ
   ├─ style.typ             PDF の見た目（インラインコード、影）
   └─ vscode-preview/       VS Code 拡張機能
```

## 変換の流れ

1. pandoc が Markdown を Typst の文書（`.typ`）に変換します。独自の書き方は、このときに Lua フィルタで処理します。
2. Typst が `.typ` を PDF にします。このとき、`source/` の外のファイルは読めないようにしています（`--root source`）。

途中の `.typ` は、元の Markdown と同じフォルダに一時的に作り、変換が終わると消します。
こうしておくと、画像のパスを Markdown に書いたままの形で使えます。

## ライセンス

このリポジトリのスクリプト、設定、拡張機能、デモ用の文書と画像は、MIT License で提供します（[LICENSE](LICENSE)）。

`setup.bat` でダウンロードするものは、それぞれの作者のライセンスに従います。

- pandoc: GPL-2.0-or-later
- Typst: Apache-2.0
- Noto Serif JP: SIL Open Font License 1.1

npm パッケージのライセンスは、各パッケージの記載を見てください。
