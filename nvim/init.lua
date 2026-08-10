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
    { "folke/lazy.nvim", commit = "306a05526ada86a7b30af95c5cc81ffba93fef97", pin = true, },
    { import = "plugins", },
  },
  checker = {
    notify = false,
    enabled = true,
    -- The checker skips pinned plugins unless this is set. Note it can only
    -- report a plugin as behind its *declared target* -- and since every spec
    -- names an explicit commit, that target is always what's checked out. So
    -- this reports nothing today; it starts mattering again for any plugin
    -- whose `commit` is removed in favour of a branch or version range.
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
