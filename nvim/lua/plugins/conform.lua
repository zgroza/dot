-- Credit: https://github.com/stevearc/conform.nvim/issues/92#issuecomment-2235105039
local function formatter()
  local args = {
    lsp_format = "fallback",
    async = false,
    timeout_ms = 1000,
  }
  local data = MiniDiff.get_buf_data()
  if not data or not data.hunks then
    vim.notify("No hunks in this buffer")
    return
  end
  local format = require("conform").format
  local ranges = {}
  for _, hunk in pairs(data.hunks) do
    if hunk.type ~= "delete" then
      -- always insert to index 1 so format below could start from last hunk, which this sort didn't mess up range
      table.insert(ranges, 1, {
        start = { hunk.buf_start, 0, },
        ["end"] = { hunk.buf_start + hunk.buf_count, 0, },
      })
    end
  end
  for _, range in pairs(ranges) do
    args.range = range
    format(args)
  end
end

return {
  "stevearc/conform.nvim",
  dependencies = {
    "nvim-mini/mini.diff",
  },
  opts = {
    formatters_by_ft = {
      markdown = { "prettier", },
      javascript = { "clang_format", },
      typescript = { "clang_format", },
      json = { "prettier", },
      yaml = { "prettier", },
      cpp = { "clang_format", },
    },
    format_on_save = nil,
  },
  config = function(opts)
    require("conform").setup(opts)
    vim.api.nvim_set_keymap("n", "<leader>fo", "",
                            { desc = "Format current buffer", callback = formatter, })
    vim.api.nvim_set_keymap("n", "<leader>F", "",
                            { desc = "Format current buffer", callback = formatter, })
  end,
}
