return {
  "nvim-telescope/telescope.nvim",
  -- v0.2.2. Pinned by commit rather than tag: a tag can be re-pointed upstream,
  -- a commit hash cannot.
  commit = "5255aa27c422de944791318024167ad5d40aad20",
  pin = true,
  dependencies = {
    { "nvim-lua/plenary.nvim", commit = "74b06c6c75e4eeb3108ec01852001636d85a932b", pin = true, },
  },
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
