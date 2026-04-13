return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set("n", "<leader>gc", "<cmd>G commit -a<CR>", { desc = "Git commit all" })
    vim.keymap.set("n", "<leader>gp", "<cmd>G push<CR>", { desc = "Git push" })
  end
}
