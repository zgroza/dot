return {
  "hrsh7th/nvim-cmp",
  commit = "2ffe79f1f021def8dd1fcd81deb16f1bb0d989f3",
  pin = true,
  dependencies = {
    { "hrsh7th/cmp-nvim-lsp", commit = "cbc7b02bb99fae35cb42f514762b89b5126651ef", pin = true, },
    { "hrsh7th/cmp-buffer",   commit = "b74fab3656eea9de20a9b8116afa3cfc4ec09657", pin = true, },
    { "hrsh7th/cmp-path",     commit = "c642487086dbd9a93160e1679a1327be111cbc25", pin = true, },
  },
  config = function()
    local cmp = require("cmp")

    cmp.setup({
      window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
}
