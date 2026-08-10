return {
  "folke/trouble.nvim",
  commit = "bd67efe408d4816e25e8491cc5ad4088e708a69a",
  pin = true,
  opts = {
    warn_no_results = false,
    open_no_results = true,
    modes = {
      lsp = {
        preview = {
          type = "split",
          relative = "win",
          position = "right",
          size = 0.5,
        },
      },
    },
  },
  cmd = "Trouble",
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle focus=false<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle focus=false filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=true<cr>",
      desc = "Lsp (Trouble)",
    },
  },
}
