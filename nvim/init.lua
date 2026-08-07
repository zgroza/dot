-- Set leader key (very first thing)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath, })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg", },
      { out,                            "WarningMsg", },
      { "\nPress any key to exit...", },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Load core configuration
require("core.options")
require("core.keymaps")

-- Load plugins using lazy.nvim
require("lazy").setup {
  spec = {
    -- lazy.nvim manages itself, so it isn't covered by the `plugins` import
    -- and would be the one thing `:Lazy update` still moved.
    { "folke/lazy.nvim", pin = true, },
    { import = "plugins", },
  },
  checker = {
    notify = false,
    enabled = true,
    -- Every plugin is `pin = true`, and the checker skips pinned plugins by
    -- default -- which would silently mean no update checks at all. This keeps
    -- the notifications while updates stay opt-in via `:Lazy update <plugin>`.
    check_pinned = true,
  },
  change_detection = {
    enabled = true,
    notify = true,
  },
}

-- Load lsp configuration
require("core.lsp")

-- Load utils
-- Source all files in lua/utils/
local utils_files = vim.fn.glob(vim.fn.stdpath("config") .. "/lua/utils" .. "/*.lua", true, true)

if utils_files then
  for _, file_path in ipairs(utils_files) do
    local ok, err = pcall(dofile, file_path)
    if not ok then
      vim.notify("Error sourcing " .. file_path .. ": " .. err, vim.log.levels.ERROR)
    end
  end
end
