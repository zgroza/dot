local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

local function setup_clangd()
  vim.lsp.config.clangd = {
    capabilities = capabilities,
    cmd = { "clangd", },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", },
    root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git", },
  }
  vim.lsp.enable("clangd")
end

local function setup_lua_ls()
  vim.lsp.config.lua_ls = {
    capabilities = capabilities,
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if
            path ~= vim.fn.stdpath("config")
            and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
        then
          return
        end
      end
    end,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = {
            "lua/?.lua",
            "lua/?/init.lua",
          },
        },
        diagnostics = {
          globals = { "vim", },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.tbl_filter(function(d)
                                     return not d:match(vim.fn.stdpath("config") .. "/?a?f?t?e?r?")
                                   end, vim.api.nvim_get_runtime_file("", true)),
        },
        telemetry = { enable = false, },
        format = {
          enable = true,
          defaultConfig = {
            indent_style = "space",
            indent_size = "2",
            max_line_length = "100",
            insert_final_newline = "true",
            align_continuous_line_space = "2",
            align_continuous_assign_statement = "true",
            align_continuous_rect_table_field = "true",
            align_call_args = "true",
            break_all_list_when_line_exceed = "true",
            keep_indents_on_empty_lines = "false",
            line_space_after_if_statement = "keep",
            line_space_after_do_statement = "keep",
            line_space_after_while_statement = "keep",
            line_space_after_repeat_statement = "keep",
            line_space_after_for_statement = "keep",
            line_space_after_local_or_assign_statement = "keep",
            line_space_after_function_statement = "keep",
            line_space_after_expression_statement = "keep",
            line_space_after_comment = "keep",
            line_space_around_block = "keep",
            quote_style = "double",
            space_around_math_operator = "true",
            space_around_assign_operator = "true",
            space_around_concat_operator = "true",
            space_around_table_field_list = "true",
            space_after_comma = "true",
            align_function_params = "true",
            trailing_table_separator = "always",
          },
        },
      },
    },
    cmd = { "lua-language-server", },
    filetypes = { "lua", },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git", },
  }
  vim.lsp.enable("lua_ls")
end

local function setup_ts_ls()
  vim.lsp.config("ts_ls", {
    init_options = { hostInfo = "neovim", },
    cmd = { "typescript-language-server", "--stdio", },
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git", },
  })
  vim.lsp.enable("ts_ls")
end

local function setup_rust_analyzer()
  vim.lsp.config.rust_analyzer = {
    capabilities = capabilities,
    cmd = { "rust-analyzer", },
    filetypes = { "rust", },
    root_markers = { "Cargo.toml", "rust-project.json", ".git", },
  }
  vim.lsp.enable("rust_analyzer")
end

if vim.fn.executable("clangd") then
  setup_clangd()
end
if vim.fn.executable("lua-language-server") then
  setup_lua_ls()
end
if vim.fn.executable("typescript-language-server") then
  setup_ts_ls()
end
vim.env.PATH = "./third_party/rust-toolchain/bin/:" .. vim.env.PATH
if vim.fn.executable("rust-analyzer") then
  setup_rust_analyzer()
end

-- Clear redundant rust-analyzer unresolvedReference semantic tokens (fixes fake macro errors)
vim.api.nvim_set_hl(0, '@lsp.type.unresolvedReference.rust', { undercurl = false, underline = false, sp = 'none', fg = 'none', bg = 'none' })

-- Make highlights appear faster (700 ms, default is ~4 s)
vim.o.updatetime = 700
local lsp_augroup = vim.api.nvim_create_augroup("LspConfig", { clear = true, })
vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_augroup,
  desc = "Setup LSP features on attach",
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client.server_capabilities.documentHighlightProvider then
      return -- Why bother? It doesn't support it anyway.
    end
    local buflocal_augroup = vim.api.nvim_create_augroup("LspHighlights_Buffer_" .. bufnr,
      {
        clear = true,
      })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", }, {
      group = buflocal_augroup,
      buffer = bufnr,
      desc = "Highlight document references",
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
      group = buflocal_augroup,
      buffer = bufnr,
      desc = "Clear document highlights",
      callback = vim.lsp.buf.clear_references,
    })
  end,
})
