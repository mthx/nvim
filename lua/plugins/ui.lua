vim.pack.add({
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

require("tokyonight").setup({ style = "night" })
vim.cmd.colorscheme("tokyonight")

require("which-key").setup({})

require("lualine").setup({
  options = {
    theme = "auto",
    component_separators = { left = "|", right = "|" },
    section_separators = {},
  },
})
