-- Define the baseline with only the 'no-vault' fallback.
---@module 'obsidian'
---@type obsidian.workspace.WorkspaceSpec[]
local workspaces = {
  {
    name = "no-vault",
    path = function()
      return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
    end,
    overrides = {
      notes_subdir = vim.NIL,
      new_notes_location = "current_dir",
      templates = {
        folder = vim.NIL,
      },
      frontmatter = { enabled = false },
    },
  },
}

-- Attempt to load device-specific workspaces from the external file.
local local_workspaces_file = vim.fn.expand("~/.config/nvim-obsidian-workspaces.lua")

--- Example ~/.config/nvim-obsidian-workspaces.lua:
-- return {
--   {
--     name = "Vault 1",
--     path = "~/vaults/Vault 1",
--   },
-- }

if vim.fn.filereadable(local_workspaces_file) == 1 then
  local ok, local_workspaces = pcall(dofile, local_workspaces_file)

  -- If the file loaded successfully and returned a table, merge it.
  if ok and type(local_workspaces) == "table" then
    for _, ws in ipairs(local_workspaces) do
      table.insert(workspaces, ws)
    end
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
    legacy_commands = false,
    sync = {
      enabled = true,
    },
    workspaces = workspaces,
  },
}
