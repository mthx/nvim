-- Options
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.autoread = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() vim.opt_local.wrap = true end,
})

-- Reload files changed outside nvim (on focus, and poll every second for background changes)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "silent! checktime",
})
local timer = vim.uv.new_timer()
timer:start(1000, 1000, vim.schedule_wrap(function()
  if vim.fn.getcmdwintype() == "" and vim.fn.mode() == "n" then
    vim.cmd("silent! checktime")
  end
end))

-- Remove default right-click popup menu
vim.cmd([[aunmenu PopUp]])
vim.api.nvim_del_augroup_by_name("nvim.popupmenu")

-- Keymaps
vim.keymap.set("n", "<Esc>", function()
  vim.cmd("nohlsearch")
  -- Close any floating windows (blame popups, hover docs, etc.)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
end)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })

vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<leader>fp", function() vim.fn.setreg("+", vim.fn.expand("%")) end, { desc = "Copy file path" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  change_detection = { notify = false },
})

-- Treesitter textobjects (explicit keymaps since config-based ones don't apply)
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
local select_modes = { "x", "o" }
for _, mode in ipairs(select_modes) do
  vim.keymap.set(mode, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end, { desc = "Around function" })
  vim.keymap.set(mode, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end, { desc = "Inside function" })
  vim.keymap.set(mode, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end, { desc = "Around class" })
  vim.keymap.set(mode, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end, { desc = "Inside class" })
  vim.keymap.set(mode, "aa", function() ts_select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
  vim.keymap.set(mode, "ia", function() ts_select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Inside parameter" })
end
