-- Define the baseline with only the 'no-vault' fallback.
---@module 'obsidian'
---@type obsidian.workspace.WorkspaceSpec[]
local workspaces = {
  {
    name = "no-vault",
    path = vim.fn.expand("~") .. "/.fallback/",
    overrides = {
      sync = {
        enabled = false,
      },
      notes_subdir = vim.NIL,
      new_notes_location = "current_dir",
      templates = {
        folder = vim.NIL,
      },
      frontmatter = { enabled = false },
    },
  },
}

vim.fn.mkdir(vim.fn.expand("~") .. "/.fallback/", "p")

-- Attempt to load device-specific workspaces from the external file.
local local_workspaces_file = vim.fn.expand("~/.config/nvim-obsidian-workspaces.lua")

--- Example ~/.config/nvim-obsidian-workspaces.lua:
-- ---@module 'obsidian'                      
-- ---@type obsidian.workspace.WorkspaceSpec[]
-- return {
--   {
--     name = "Vault 1",
--     path = "~/vaults/Vault 1",
--   },
--   overrides = {
--     sync = {
--       enabled = true,
--     },
--   },
-- }

if vim.fn.filereadable(local_workspaces_file) == 1 then
  local ok, local_workspaces = pcall(dofile, local_workspaces_file)

  if ok and type(local_workspaces) == "table" then
    -- Since no-vault is a fallback, add it last
    table.insert(local_workspaces, workspaces[1])
    workspaces = local_workspaces
  end
end

return {
  "obsidian-nvim/obsidian.nvim",
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  version = "*",
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    sync = {
      enabled = false,
    },
    legacy_commands = false,
    workspaces = workspaces,
    ---@param title string|?
    ---@param dir obsidian.Path|?
    ---@return string
    note_id_func = function(title, dir)
      if not title then
        return require("obsidian.builtin").title_id(title, dir)
      end

      if not dir then
        return title
      end

      if (require("obsidian.path").new(dir) / title):with_suffix(".md", true):exists() then
        return require("obsidian.builtin").title_id(title, dir)
      end

      return title
    end,
  },
}
