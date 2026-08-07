return {
  "folke/tokyonight.nvim",
  pin = true,
  lazy = false,
  priority = 1000,
  config = function ()
    vim.cmd[[colorscheme tokyonight-night]]
  end
}
