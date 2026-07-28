return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
    popupmenu = {
      enabled = true,
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  }
}
