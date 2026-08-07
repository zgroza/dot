return {
  "nvim-telescope/telescope.nvim",
  tag = "v0.2.2",
  pin = true,
  dependencies = { { "nvim-lua/plenary.nvim", pin = true, }, },
  config = function()
    require("telescope").setup {
      defaults = {
        layout_strategy = "vertical",
        layout_config = { height = 0.95, width = 0.95, },
        preview = {
          treesitter = true,
          -- Telescope shells out to `file --mime-type -b "<path>"` through
          -- io.popen with the path in double quotes only (buffer_previewer.lua
          -- :173). $(), backticks and " all still expand there, so merely
          -- hovering a crafted filename in a picker executes it. Still present
          -- in v0.2.2. Disabling costs only binary-file detection in previews.
          check_mime_type = false,
        },
      },
      pickers = {
        lsp_dynamic_workspace_symbols = {
          fname_width = 100, show_line = true,
        },
        lsp_references = {
          fname_width = 100, show_line = true,
        },
        lsp_incoming_calls = {
          fname_width = 100, show_line = true,
        },
        lsp_outgoing_calls = {
          fname_width = 100, show_line = true,
        },
      },
    }
  end,
}
