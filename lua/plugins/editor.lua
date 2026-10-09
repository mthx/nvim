vim.pack.add({
  { src = "https://github.com/nvim-telescope/telescope.nvim", version = vim.version.range("0.2.*") },
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  "https://github.com/lewis6991/gitsigns.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/MunifTanjim/nui.nvim",
})

-- Telescope
require("telescope").setup({
  extensions = { fzf = {} },
})
require("telescope").load_extension("fzf")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", function() builtin.find_files({ hidden = true, file_ignore_patterns = { "^%.git/" } }) end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>fo", function() builtin.oldfiles({ cwd_only = true }) end, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume search" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Symbols (file)" })
vim.keymap.set("n", "<leader>fS", builtin.lsp_dynamic_workspace_symbols, { desc = "Symbols (workspace)" })

-- Treesitter
require("nvim-treesitter").install({
  "lua", "vim", "vimdoc",
  "typescript", "tsx", "javascript",
  "html", "css", "json",
  "markdown", "markdown_inline",
  "bash",
})
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

local ts_move = require("nvim-treesitter-textobjects.move")
local ts_select = require("nvim-treesitter-textobjects.select")

-- Move: ]f/[f (function), ]c/[c (class), ]a/[a (parameter)
vim.keymap.set("n", "]f", function() ts_move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
vim.keymap.set("n", "[f", function() ts_move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Previous function" })
vim.keymap.set("n", "]c", function() ts_move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
vim.keymap.set("n", "[c", function() ts_move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Previous class" })
vim.keymap.set("n", "]a", function() ts_move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "Next parameter" })
vim.keymap.set("n", "[a", function() ts_move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Previous parameter" })

-- Select: af/if (function), ac/ic (class), aa/ia (parameter)
for _, mode in ipairs({ "x", "o" }) do
  vim.keymap.set(mode, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end, { desc = "Around function" })
  vim.keymap.set(mode, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end, { desc = "Inside function" })
  vim.keymap.set(mode, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end, { desc = "Around class" })
  vim.keymap.set(mode, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end, { desc = "Inside class" })
  vim.keymap.set(mode, "aa", function() ts_select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
  vim.keymap.set(mode, "ia", function() ts_select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Inside parameter" })
end

-- Git
require("gitsigns").setup({})
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Blame line" })

-- File explorer
require("neo-tree").setup({
  filesystem = {
    follow_current_file = { enabled = true },
  },
})
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File explorer" })
