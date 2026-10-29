// Render a Markdown file with the md2pdf plugin, the way VS Code's preview
// would, and write a standalone HTML page for checking in a browser.
//
//   node test/render.js <input.md> <output.html> [document-path]
//
// document-path (default: input.md) is what the preview would report as the
// current document; icons are looked up from its folder upwards.

const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

const root = path.resolve(__dirname, '..', '..', '..');
const MarkdownIt = require(path.join(root, 'bin', 'npm-tools', 'node_modules', 'markdown-it'));
const md2pdf = require('../md2pdf-plugin');

const [input, output, docArg] = process.argv.slice(2);
if (!input || !output) {
  console.error('usage: node test/render.js <input.md> <output.html> [document-path]');
  process.exit(2);
}
const docPath = path.resolve(docArg || input);

// Same calling pattern as VS Code: it parses with currentDocument unset and
// passes the document only when rendering.
const md = new MarkdownIt({ html: true, linkify: true }).use(md2pdf);
const tokens = md.parse(fs.readFileSync(input, 'utf8'), { currentDocument: undefined });
const body = md.renderer.render(tokens, md.options, { currentDocument: { fsPath: docPath } });
const css = fs.readFileSync(path.join(__dirname, '..', 'preview.css'), 'utf8');
const base = pathToFileURL(path.dirname(docPath) + path.sep).href;

fs.writeFileSync(output, `<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<base href="${base}">
<title>md2pdf preview test</title>
<style>
body { font-family: "Segoe UI", "Yu Gothic UI", sans-serif; font-size: 14px; line-height: 1.6;
       max-width: 860px; margin: 24px auto; padding: 0 26px; color: #1f2328; background: #fff; }
img { max-width: 100%; }
code { font-size: 1em; }
</style>
<style>${css}</style>
</head><body>
${body}
</body></html>
`);
console.log('wrote', output);
