return {
  "folke/tokyonight.nvim",
  commit = "cdc07ac78467a233fd62c493de29a17e0cf2b2b6",
  pin = true,
  lazy = false,
  priority = 1000,
  config = function ()
    vim.cmd[[colorscheme tokyonight-night]]
  end
}
