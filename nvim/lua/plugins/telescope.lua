return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim", },
  config = function()
    require("telescope").setup {
      defaults = {
        layout_strategy = "vertical",
        layout_config = { height = 0.95, width = 0.95, },
        preview = {
          treesitter = true,
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
