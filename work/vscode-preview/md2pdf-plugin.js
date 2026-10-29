// markdown-it plugin that mirrors md2pdf's pandoc filters (work/*.lua) in the
// VS Code Markdown preview, so the preview looks close to the PDF:
//
//   [text]{color=red}        coloured text                  (color.lua)
//   <!-- origin: N -->       ## / ### / #### numbering      (numbering.lua)
//   <!-- pagebreak -->       page-break marker              (pagebreak.lua)
//   :icon_name:              _icons/icon_name.<ext> inline  (icons.lua)
//   image alone in a para    drop shadow (CSS)              (shadow.lua)
//   line break between two East Asian characters is dropped (east_asian_line_breaks)
//
// No dependency on the vscode module, so it can also be run with plain
// markdown-it for testing.

const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------- colours

// Typst's named colours (the PDF uses these), as CSS hex values.
const NAMED_COLORS = {
  black: '#000000', gray: '#aaaaaa', silver: '#dddddd', white: '#ffffff',
  navy: '#001f3f', blue: '#0074d9', aqua: '#7fdbff', teal: '#39cccc',
  eastern: '#239dad', purple: '#b10dc9', fuchsia: '#f012be', maroon: '#85144b',
  red: '#ff4136', orange: '#ff851b', yellow: '#ffdc00', olive: '#3d9970',
  green: '#2ecc40', lime: '#01ff70',
};

function resolveColor(value) {
  const v = value.trim().toLowerCase();
  if (Object.prototype.hasOwnProperty.call(NAMED_COLORS, v)) return NAMED_COLORS[v];
  if (/^#[0-9a-f]{3}$/.test(v) || /^#[0-9a-f]{6}$/.test(v)) return v;
  return null;
}

// Parse a pandoc attribute block body ("color=red .cls #id"); null if invalid.
function parseAttributes(body) {
  const attrs = {};
  const re = /\s*(?:(\.[\w-]+)|(#[\w-]+)|([\w-]+)=(?:"([^"]*)"|'([^']*)'|([^\s"']+)))\s*/y;
  let pos = 0;
  if (body.trim() === '') return null;
  while (pos < body.length) {
    re.lastIndex = pos;
    const m = re.exec(body);
    if (!m || m[0] === '') return null;
    if (m[3]) attrs[m[3]] = m[4] ?? m[5] ?? m[6];
    pos = re.lastIndex;
  }
  return attrs;
}

// Inline rule: [text]{attrs} -> <span style="color: ...">text</span>
function spanRule(state, silent) {
  if (state.src.charCodeAt(state.pos) !== 0x5b /* [ */) return false;
  const labelStart = state.pos + 1;
  const labelEnd = state.md.helpers.parseLinkLabel(state, state.pos, false);
  if (labelEnd < 0) return false;
  const m = state.src.slice(labelEnd + 1).match(/^\{([^{}\n]*)\}/);
  if (!m) return false;
  const attrs = parseAttributes(m[1]);
  if (!attrs) return false;

  if (!silent) {
    const color = attrs.color !== undefined ? resolveColor(attrs.color) : null;
    const open = state.push('md2pdf_span_open', 'span', 1);
    if (color) open.attrSet('style', 'color: ' + color);
    const oldMax = state.posMax;
    state.pos = labelStart;
    state.posMax = labelEnd;
    state.md.inline.tokenize(state);
    state.posMax = oldMax;
    state.push('md2pdf_span_close', 'span', -1);
  }
  state.pos = labelEnd + 1 + m[0].length;
  return true;
}

// ---------------------------------------------------- block-level comments

const ORIGIN_RE = /^\s*<!--\s*origin\s*:\s*(\d+)\s*-->\s*$/;
const PAGEBREAK_RE = /^\s*<!--\s*pagebreak\s*-->\s*$/i;

function pagebreakRule(state) {
  for (const token of state.tokens) {
    if (token.type === 'html_block' && PAGEBREAK_RE.test(token.content)) {
      token.type = 'md2pdf_pagebreak';
    }
  }
}

const TOP = 2;     // ##
const BOTTOM = 4;  // ####

function numberingRule(state) {
  const tokens = state.tokens;
  let origin = null;
  for (const token of tokens) {
    if (token.type === 'html_block') {
      const m = token.content.match(ORIGIN_RE);
      if (m) { origin = parseInt(m[1], 10); break; }
    }
  }
  if (origin === null) return;

  const counters = {};
  let started = false;
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.type !== 'heading_open') continue;
    const level = parseInt(token.tag.slice(1), 10);
    if (level < TOP || level > BOTTOM) continue;

    if (level === TOP) {
      counters[TOP] = started ? counters[TOP] + 1 : origin;
      started = true;
    } else {
      if (counters[level - 1] === undefined) continue;  // no parent: unnumbered
      counters[level] = (counters[level] || 0) + 1;
    }
    for (let l = level + 1; l <= BOTTOM; l++) delete counters[l];

    const parts = [];
    for (let l = TOP; l <= level; l++) parts.push(String(counters[l]));
    const inline = tokens[i + 1];
    const label = new state.Token('text', '', 0);
    label.content = parts.join('-') + '. ';
    inline.children.unshift(label);
  }
}

// ----------------------------------------------------------- inline passes

const WIDE_RE = /[ᄀ-ᇿ⺀-꓏가-힣豈-﫿︰-﹏＀-｠￠-￦\u{20000}-\u{3ffff}]/u;

function isWide(ch) {
  return ch !== undefined && WIDE_RE.test(ch);
}

// Text of the nearest text-bearing token before/after index i (skipping
// opening/closing markers such as strong_open or md2pdf_span_close).
function neighbourText(children, i, step) {
  for (let j = i + step; j >= 0 && j < children.length; j += step) {
    const t = children[j];
    if (t.type === 'text' || t.type === 'code_inline') return t.content;
    if (t.nesting === 0) return '';
  }
  return '';
}

// A soft line break between two East Asian characters disappears (no space).
function eastAsianBreaksRule(state) {
  for (const block of state.tokens) {
    if (block.type !== 'inline' || !block.children) continue;
    const children = block.children;
    block.children = children.filter((t, i) => {
      if (t.type !== 'softbreak') return true;
      const before = Array.from(neighbourText(children, i, -1)).pop();
      const after = Array.from(neighbourText(children, i, +1))[0];
      return !(isWide(before) && isWide(after));
    });
  }
}

// An image that is the only thing in its paragraph gets the drop-shadow class.
function shadowRule(state) {
  const tokens = state.tokens;
  for (let i = 0; i + 2 < tokens.length; i++) {
    if (tokens[i].type !== 'paragraph_open') continue;
    const inline = tokens[i + 1];
    if (inline.type === 'inline' && inline.children &&
        inline.children.length === 1 && inline.children[0].type === 'image') {
      inline.children[0].attrJoin('class', 'md2pdf-shadow');
    }
  }
}

const ICON_EXTENSIONS = ['svg', 'png', 'jpg', 'jpeg', 'gif', 'webp'];
const ICON_RE = /:(icon_[A-Za-z0-9_-]+):/g;

// Nearest "_icons" folder at or above the document's folder.
function findIconDir(docDir) {
  let dir = docDir;
  for (;;) {
    const candidate = path.join(dir, '_icons');
    try {
      if (fs.statSync(candidate).isDirectory()) return candidate;
    } catch (_) { /* not here */ }
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function iconFile(iconDir, name) {
  for (const ext of ICON_EXTENSIONS) {
    const file = path.join(iconDir, name + '.' + ext);
    if (fs.existsSync(file)) return file;
  }
  return null;
}

// Icons are resolved when rendering, not when parsing: VS Code parses with
// env.currentDocument unset and only passes the document at render time.
// At parse time, text that may contain icons is just marked.
function iconsRule(state) {
  for (const block of state.tokens) {
    if (block.type !== 'inline' || !block.children) continue;
    for (const t of block.children) {
      if (t.type === 'text' && t.content.includes(':icon_')) t.type = 'md2pdf_icon_text';
    }
  }
}

function documentDir(env) {
  const doc = env && env.currentDocument;
  const docPath = doc && (doc.fsPath || (typeof doc === 'string' ? doc : null));
  return docPath ? path.dirname(docPath) : null;
}

// Render a marked text token: :icon_name: -> <img> through the image renderer
// (so VS Code rewrites src for its webview); unknown names stay as text.
function renderIconText(tokens, idx, options, env, self) {
  const md = this;
  const text = tokens[idx].content;
  const docDir = documentDir(env);
  const iconDir = docDir && findIconDir(docDir);
  if (!iconDir) return md.utils.escapeHtml(text);

  const Token = tokens[idx].constructor;
  let html = '';
  let pos = 0;
  let searchFrom = 0;
  for (;;) {
    ICON_RE.lastIndex = searchFrom;
    const m = ICON_RE.exec(text);
    if (!m) break;
    const file = iconFile(iconDir, m[1]);
    if (!file) {
      // the closing ':' may open the next icon
      searchFrom = m.index + m[0].length - 1;
      continue;
    }
    html += md.utils.escapeHtml(text.slice(pos, m.index));
    const img = new Token('image', 'img', 0);
    const rel = path.relative(docDir, file).split(path.sep).map(encodeURIComponent).join('/');
    img.attrs = [['src', rel], ['alt', ''], ['class', 'md2pdf-icon'], ['title', m[1]]];
    img.children = [];
    img.content = m[1];
    html += self.rules.image ? self.rules.image([img], 0, options, env, self) : self.renderToken([img], 0, options);
    pos = searchFrom = m.index + m[0].length;
  }
  return html + md.utils.escapeHtml(text.slice(pos));
}

// ---------------------------------------------------------------- plugin

module.exports = function md2pdfPlugin(md) {
  md.inline.ruler.before('link', 'md2pdf_span', spanRule);

  // Order matters: shadow before icons (icons are not screenshots), line
  // breaks before icons (":icon_x:" counts as ASCII text, as in pandoc).
  const after = md.core.ruler.__find__('text_join') >= 0 ? 'text_join' : 'inline';
  md.core.ruler.after(after, 'md2pdf_pagebreak', pagebreakRule);
  md.core.ruler.after('md2pdf_pagebreak', 'md2pdf_numbering', numberingRule);
  md.core.ruler.after('md2pdf_numbering', 'md2pdf_east_asian_breaks', eastAsianBreaksRule);
  md.core.ruler.after('md2pdf_east_asian_breaks', 'md2pdf_shadow', shadowRule);
  md.core.ruler.after('md2pdf_shadow', 'md2pdf_icons', iconsRule);

  md.renderer.rules.md2pdf_icon_text = renderIconText.bind(md);
  md.renderer.rules.md2pdf_pagebreak = () =>
    '<div class="md2pdf-pagebreak" role="separator" aria-label="page break"></div>\n';

  return md;
};
