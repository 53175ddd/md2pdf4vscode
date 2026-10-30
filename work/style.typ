// Typst styles inserted at the top of every document (include-in-header in defaults.yaml).

// Inline code (`code`): monospace text with a light, bordered background, like GitHub / Discord.
//
// Built from three parts instead of one box():
//   [left cap] highlight(code, top/bottom border only) [right cap]
// - A box cannot be split across lines, so a long code span left big gaps in the
//   justified line before it. highlight() wraps like normal text.
// - highlight() draws one rectangle per font run (Consolas / BIZ UDGothic), so a
//   full border would show seams inside mixed Latin/Japanese code. Top and bottom
//   lines at fixed heights join up seamlessly; the left/right edges are drawn once
//   by the caps.
#let inline-code-fill   = rgb("#f3f4f6")  // background
#let inline-code-stroke = rgb("#d0d7de")  // border
#let inline-code-text   = rgb("#c7254e")  // text colour
#let inline-code-pad    = 2.5pt           // space between border and text, left/right
#let inline-code-top    = 0.9em           // border height above the baseline
#let inline-code-bottom = 0.3em           // border depth below the baseline

#let inline-code-cap(side) = {
  let line = 0.5pt + inline-code-stroke
  box(
    width: inline-code-pad,
    height: inline-code-top + inline-code-bottom,
    baseline: inline-code-bottom,
    fill: inline-code-fill,
    stroke: (top: line, bottom: line, (side): line),
    radius: if side == "left" { (top-left: 2pt, bottom-left: 2pt) } else { (top-right: 2pt, bottom-right: 2pt) },
  )
}

#show raw.where(block: false): it => {
  let line = 0.5pt + inline-code-stroke
  inline-code-cap("left")
  sym.wj  // no line break between a cap and the code
  highlight(
    fill: inline-code-fill,
    stroke: (top: line, bottom: line),
    top-edge: inline-code-top,
    bottom-edge: -inline-code-bottom,
    text(fill: inline-code-text, it),
  )
  sym.wj
  inline-code-cap("right")
}

// Drop shadow for images placed on their own line (wrapped by work/shadow.lua).
// Typst has no blur filter, so a soft shadow is faked by stacking translucent
// rounded rectangles, from shadow-blur smaller to shadow-blur larger than the
// image. Where they all overlap it is darkest; across the edge the number of
// layers (and so the darkness) falls off gradually over 2 x shadow-blur.
#let shadow-dx     = 1.5pt               // offset to the right
#let shadow-dy     = 2.5pt               // offset downwards
#let shadow-blur   = 5pt                 // half the width of the soft edge
#let shadow-steps  = 16                  // layers; more = smoother fade
#let shadow-color  = black
#let shadow-alpha  = 40%                 // opacity in the darkest part (hidden under the image)

#let shadow-image(body) = layout(size => {
  let s = measure(body, width: size.width)
  let layer = shadow-color.transparentize(100% - shadow-alpha / shadow-steps)
  block(
    width: s.width,
    height: s.height,
    // move to the next page as a whole instead of being cut at the page end
    breakable: false,
    // keep following text clear of the shadow
    below: 1.2em + shadow-dy + shadow-blur,
    {
      for i in range(shadow-steps) {
        // from -blur (inside the image) to +blur (outside)
        let grow = shadow-blur * (2 * i / (shadow-steps - 1) - 1)
        place(
          dx: shadow-dx - grow,
          dy: shadow-dy - grow,
          rect(
            width: s.width + 2 * grow,
            height: s.height + 2 * grow,
            radius: calc.max(grow, 0pt),
            fill: layer,
            stroke: none,
          ),
        )
      }
      place(body)
    },
  )
})

// Italic (*text* / _text_). Typst does not slant fonts that have no italic
// face, and Noto Serif JP has none, so emphasis would look like plain text.
// - Latin: taken from Cambria, which has a real italic and ships with Windows.
//   (emph itself switches the style to italic; setting style here too would
//   toggle it back to upright.)
// - Japanese: no Japanese font has an italic, so each character is slanted
//   with skew(), like a browser's synthetic oblique. Each character is its own
//   box so the line can still break inside the emphasis; a zero-width space
//   marks the break points, except before characters that must not start a
//   line (small kana, prolonged sound mark, iteration marks).
#let emph-latin-font = "Cambria"
#let emph-cjk-font   = "Noto Serif JP"  // keep in line with mainfont in defaults.yaml
#let emph-slant      = 12deg
#let emph-no-break-before = "ーぁぃぅぇぉっゃゅょゎゕゖァィゥェォッャュョヮヵヶ々ゝゞヽヾ"

#let emph-oblique(c) = box(skew(ax: -emph-slant, reflow: false, c))

#show emph: set text(font: (emph-latin-font, emph-cjk-font))
#show emph: it => {
  show regex("[\p{Han}\p{Hiragana}\p{Katakana}ー々〆ヶ]+"): run => {
    let chars = run.text.clusters()
    for (i, c) in chars.enumerate() {
      if i > 0 and not emph-no-break-before.contains(c) { sym.zws }
      emph-oblique(c)
    }
  }
  it
}

// Code blocks (```): light grey background with a thin border, like GitHub / Discord.
#let code-block-fill   = rgb("#f6f8fa")
#let code-block-stroke = rgb("#d0d7de")

#show raw.where(block: true): it => block(
  width: 100%,
  fill: code-block-fill,
  stroke: 0.5pt + code-block-stroke,
  radius: 3pt,
  inset: (x: 8pt, y: 7pt),
  it,
)

// Block quotes (>): background plus a bar on the left, instead of Typst's
// plain indentation.
#let quote-fill = rgb("#f3f4f6")
#let quote-bar  = rgb("#c4c9d0")
#let quote-text = rgb("#4b5563")

#show quote.where(block: true): it => block(
  width: 100%,
  fill: quote-fill,
  stroke: (left: 3pt + quote-bar),
  radius: (right: 3pt),
  inset: (left: 10pt, right: 8pt, y: 7pt),
  text(fill: quote-text, it.body),
)
