// VS Code entry point: hand the markdown-it plugin to the built-in Markdown preview.
const md2pdf = require('./md2pdf-plugin');

function activate() {
  return {
    extendMarkdownIt(md) {
      return md.use(md2pdf);
    },
  };
}

function deactivate() {}

module.exports = { activate, deactivate };
