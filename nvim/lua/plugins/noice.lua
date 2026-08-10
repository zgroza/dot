return {
  "folke/noice.nvim",
  commit = "7bfd942445fb63089b59f97ca487d605e715f155",
  pin = true,
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
    { "MunifTanjim/nui.nvim", commit = "de740991c12411b663994b2860f1a4fd0937c130", pin = true, },
  }
}
