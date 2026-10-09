-- Prebuilt fuzzy-matcher binaries are only downloaded for release tags.
vim.pack.add({
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("blink.cmp").setup({
  keymap = { preset = "enter" },
  appearance = { nerd_font_variant = "mono" },
  sources = {
    default = { "lsp", "path", "buffer" },
  },
})
