---
title: md2pdf サンプル
author: md2pdf
date: 2026-10-22
---

# はじめに

<!-- origin: 1 -->

これは **日本語** の Markdown を PDF に変換するサンプルです。English text mixed in. 句読点、「かぎ括弧」、全角記号（）も確認します。

上の `<!-- origin: 1 -->` によって、`##` 以下の見出しに章番号が自動で付きます。

## リスト

- 項目その一
- 項目その二
  - 入れ子の項目

1. 番号付き
2. リスト

### 入れ子の見出し

`###` は「1-1.」、`####` は「1-1-1.」の形になります。

## 表

| 名前 | 用途 | 備考 |
|------|------|------|
| pandoc | Markdown → Typst | 3.12.1 |
| typst | Typst → PDF | 0.15.1 |

## コード

```python
def hello(name: str) -> str:
    return f"こんにちは、{name}さん"
```

インラインコード `run.bat` も使えます。

> 引用ブロックです。

- [x] 完了したタスク
- [ ] 未完了のタスク

数式: $E = mc^2$

## 文字色

[赤い文字]{color=red}、[**太字の青**]{color=blue}、[カラーコード指定]{color="#c00000"}、
[入れ子で[内側だけ緑]{color=green}になる]{color=orange}。

## 改行

日本語の文を途中で
改行しても、PDF では
空白が入らずにつながります。
English lines are
joined with a space.
[色付きの文字]{color=red}
の前後で改行しても同じです。

<!-- pagebreak -->

## 改ページ

この節は、直前の `<!-- pagebreak -->` によって 2 ページ目から始まります。

## アイコン

`source/_icons/` に置いた画像を `:icon_名前:` で文中に入れられます。
赤い丸 :icon_test_red: と青い四角:icon_test_blue:を文字の高さで並べます。

- 詰めて書く: :icon_test_red::icon_test_blue::icon_test_red:
- 空白で区切る: :icon_test_red: :icon_test_blue: :icon_test_red:
- 文末に置く: 確認済み:icon_test_red:。
- 強調や色指定の中: **太字 :icon_test_blue:**、[赤字 :icon_test_red:]{color=red}
- 登録されていない名前はそのまま: :icon_not_found:

## 画像

段落に画像だけを置くと、影が付きます（文中に置いた画像には付きません）。

![ウィンドウの図](img/window.svg)
