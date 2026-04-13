return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "folke/trouble.nvim",
  },
  event = "VeryLazy",
  opts = function(_, opts)
    local symbols = require("trouble").statusline({
      mode = "lsp_document_symbols",
      groups = {},
      title = false,
      filter = { range = true, },
      format = "{kind_icon}{symbol.name:Normal}",
      hl_group = "lualine_c_normal",
    })
    opts.sections = {
      lualine_c = {
        "filename",
        {
          symbols.get,
          cond = symbols.has,
        },
      },
    }
    opts.winbar = {
      lualine_a = {},
      lualine_b = { "diff", "diagnostics", },
      lualine_c = {
        {
          "filename",
          path = 1,
        },
      },
      lualine_x = { "encoding", "fileformat", "filetype", },
    }
    opts.inactive_winbar = {
      lualine_a = {},
      lualine_b = { "diff", "diagnostics", },
      lualine_c = { "filename", },
      lualine_x = { "encoding", "fileformat", "filetype", },
    }
    opts.options = {
      theme = "tokyonight-night",
      globalstatus = true,
      always_show_tabline = true,
    }
    opts.tabline = {
      lualine_a = {
        {
          "tabs",
          mode = 2,
        },
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { "buffers", },
    }
  end,
}
