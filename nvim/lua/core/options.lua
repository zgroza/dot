-- General editor options
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.number = true         -- Relative line numbers
vim.opt.syntax = "on"         -- Enable syntax highlighting

-- Indenting
vim.opt.expandtab = true -- On pressing tab, insert spaces
vim.opt.tabstop = 2      -- Show existing tab with 2 spaces width
vim.opt.softtabstop = 2  -- When editing, backspace/delete tabs with 2 spaces
vim.opt.shiftwidth = 2   -- When indenting with '>', use 2 spaces width

-- Filetype detection
vim.cmd("filetype plugin indent on")

-- Neovim-specific UI improvements
vim.opt.termguicolors = true  -- Enable 24-bit RGB colors
vim.opt.mouse = "a"           -- Enable mouse support in all modes
vim.opt.winborder = "rounded" -- Border for floating windows
vim.opt.undofile = true       -- Persistent undo
vim.opt.hlsearch = true       -- Highlight search results
vim.opt.incsearch = true      -- Incremental search
vim.opt.wrap = true           -- Wrap lines
vim.opt.scrolloff = 8         -- Lines of context around the cursor
vim.opt.laststatus = 3        -- Always show statusline
vim.opt.virtualedit = "block" -- Block can select outside of present text
vim.opt.conceallevel = 2

-- Folds config
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "auto"

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- You can add other general settings here
