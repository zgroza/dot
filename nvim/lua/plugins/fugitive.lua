return {
  'tpope/vim-fugitive',
  commit = "3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0",
  pin = true,
  config = function()
    vim.keymap.set("n", "<leader>gc", "<cmd>G commit -a<CR>", { desc = "Git commit all" })
    vim.keymap.set("n", "<leader>gp", "<cmd>G push<CR>", { desc = "Git push" })
  end
}
