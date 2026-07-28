-- Global keybindings
-- Some quality-of-life things
vim.keymap.set("n", "<leader>q", vim.cmd.quit, { desc = "Close window", })
vim.keymap.set("n", "<leader>Q", vim.cmd.qall, { desc = "Close all windows", })
vim.keymap.set("n", "<leader>w", vim.cmd.update, { desc = "Save file if modified", })
-- Clipboard stuff
vim.keymap.set("n", "<M-a>", function()
                 vim.api.nvim_win_set_cursor(0, { 1, 0, })
                 vim.cmd("normal! V")
                 vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0, })
               end, { desc = "Select whole file.", })
vim.keymap.set("n", "<M-y>", ":%y+<CR>", { desc = "Copy whole file to clipboard.", })
vim.keymap.set("n", "<M-p>", function()
                 local clipboard_content = vim.fn.getreg("+")
                 local lines = vim.split(clipboard_content, "\n")
                 vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
               end, { desc = "Replace buffer with clipboard.", })
vim.keymap.set("n", "<leader>pw", "viwP", { desc = "Replace the current word with the buffer.", })
vim.keymap.set("n", "<leader>pW", "viWP", { desc = "Replace the current Word with the buffer.", })
vim.keymap.set("n", "<leader>p\"", "vi\"P", { desc = "Replace what's inside brackets with the buffer.", })

local function copy_path(to_expand)
  local path = vim.fn.expand(to_expand)
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '" to the clipboard!')
end
local function copy_rel_path()
  copy_path("%:.")
end
local function copy_abs_path()
  copy_path("%:p")
end
vim.keymap.set("n", "<leader>y", copy_rel_path, { desc = "Copy relative path", })
vim.keymap.set("n", "<leader>Y", copy_abs_path, { desc = "Copy relative path", })
-- System clipboard integration
vim.opt.clipboard = "unnamed,unnamedplus"
vim.g.clipboard = "osc52"
if vim.env.TMUX ~= nil then
  local copy = { "tmux", "load-buffer", "-w", "-", }
  local paste = { "bash", "-c", "tmux refresh-client -l && sleep 0.2 && tmux save-buffer -", }
  vim.g.clipboard = {
    name = "tmux",
    copy = {
      ["+"] = copy,
      ["*"] = copy,
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
    cache_enabled = 0,
  }
end
vim.api.nvim_set_keymap("i", "<C-v>", "<C-R>+", { noremap = true, silent = true, })
vim.api.nvim_set_keymap("x", "<C-c>", '"+y', { noremap = true, silent = true, })

-- Session saving
local function _create_new_session()
  vim.ui.input({
                 prompt = "Enter new session name: ",
                 default = "session",
               }, function(input)
                 if not input or input == "" then
                   vim.notify("Session save aborted.", "info")
                   return
                 end
                 local filename = vim.fn.expand("~/" .. input .. ".nvim")
                 local cmd = "mksession! " .. vim.fn.fnameescape(filename) .. " | qa"
                 vim.cmd(cmd)
               end)
end

local function _handle_save_choice(choice)
  if not choice then
    vim.notify("Session save aborted.", "info")
    return
  end

  if choice == "New session..." then
    _create_new_session()
  else
    local cmd = "mksession! " .. vim.fn.fnameescape(choice) .. " | qa"
    vim.cmd(cmd)
  end
end

local function save_and_quit()
  local session_files = vim.fn.glob(vim.fn.expand("~/") .. "*.nvim", true, true)
  local picker_items = vim.deepcopy(session_files)
  table.insert(picker_items, 1, "New session...")

  vim.ui.select(picker_items, {
                  prompt = "Save to existing session or create new:",
                  format_item = function(item)
                    return item == "New session..." and item or vim.fn.fnamemodify(item, ":t:r")
                  end,
                }, _handle_save_choice)
end

local function load_session()
  local session_files = vim.fn.glob(vim.fn.expand("~/") .. "*.nvim", true, true)

  if vim.tbl_isempty(session_files) then
    vim.notify("No session files found in home directory.", "warn")
    return
  end

  vim.ui.select(session_files, {
                  prompt = "Select a session to restore:",
                  format_item = function(item)
                    return vim.fn.fnamemodify(item, ":t:r")
                  end,
                }, function(choice)
                  if not choice then
                    vim.notify("Session restore aborted.", "info")
                    return
                  end
                  vim.cmd("source " .. vim.fn.fnameescape(choice))
                  vim.notify("Session restored from: " .. vim.fn.fnamemodify(choice, ":t:r"), "info")
                end)
end

vim.keymap.set("n", "<leader>ms", save_and_quit, {
  noremap = true,
  silent = true,
  desc = "Save session and quit",
})
vim.keymap.set("n", "<leader>sl", load_session, {
  noremap = true,
  silent = true,
  desc = "Load session",
})

-- tab switching
vim.keymap.set("n", "<leader>tt", "<C-w>T", {
  noremap = true,
  silent = true,
  desc = "Move window to new tab",
})
vim.keymap.set("n", "<m-r>", ":vertical winc ]<cr>", {
  noremap = true,
  silent = true,
  desc = "Jump to definition in vertical split",
})
vim.keymap.set("n", "<leader><m-r>", ":vertical winc ]<cr><C-w>T", {
  noremap = true,
  silent = true,
  desc = "Jump to definition in new tab",
})
vim.keymap.set("n", "<leader><tab>", ":tabnext<cr>", {
  noremap = true,
  silent = true,
  desc = "Go to next tab",
})
vim.keymap.set("n", "<leader><s-tab>", ":tabprevious<cr>", {
  noremap = true,
  silent = true,
  desc = "Go to previous tab",
})
vim.keymap.set("n", "<m-tab>", ":tabnext<cr>", {
  noremap = true,
  silent = true,
  desc = "Go to next tab",
})
vim.keymap.set("n", "<leader><m-tab>", ":tabprevious<cr>", {
  noremap = true,
  silent = true,
  desc = "Go to previous tab",
})
-- split creation
vim.keymap.set("n", "<leader>-", ":split<cr>", { desc = "create horizontal split", })
vim.keymap.set("n", "<leader>=", ":vsplit<cr>", { desc = "create vertical split", })
-- split switching
vim.keymap.set("n", "<m-h>", "<c-w>h", { desc = "go to left split", })
vim.keymap.set("n", "<m-j>", "<c-w>j", { desc = "go to lower split", })
vim.keymap.set("n", "<m-k>", "<c-w>k", { desc = "go to upper split", })
vim.keymap.set("n", "<m-l>", "<c-w>l", { desc = "go to right split", })
-- move splits using alt+shift+h/j/k/l
vim.keymap.set("n", "<m-s-h>", "<c-w>h", { desc = "move split to far left (alt+shift+h)", })
vim.keymap.set("n", "<m-s-j>", "<c-w>j", { desc = "move split to very bottom (alt+shift+j)", })
vim.keymap.set("n", "<m-s-k>", "<c-w>k", { desc = "move split to very top (alt+shift+k)", })
vim.keymap.set("n", "<m-s-l>", "<c-w>l", { desc = "move split to far right (alt+shift+l)", })
-- lsp
local opts = { noremap = true, silent = true, }
-- `vim.lsp.buf.references` default mapping: grr
-- `vim.lsp.buf.implementation,` default mapping: gri
-- `vim.lsp.buf.signature_help` default mapping in insert mode: ctrl+s
vim.keymap.set("n", "<leader>k", vim.lsp.buf.signature_help, opts)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
-- `vim.lsp.buf.rename` default mapping: grn
-- `vim.lsp.buf.code_action` default mapping: gra
vim.keymap.set("n", "[d", function()
                 vim.diagnostic.jump({ count = -1, float = true, })
               end, opts)
vim.keymap.set("n", "]d", function()
                 vim.diagnostic.jump({ count = 1, float = true, })
               end, opts)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "<leader>lj", "<cmd>lua vim.diagnostic.open_float()<cr>", opts)
vim.keymap.set("n", "<leader>k", function()
                 local new_config = not vim.diagnostic.config().virtual_lines
                 vim.diagnostic.config({ virtual_lines = new_config, })
               end, { desc = "toggle diagnostic virtual_lines", })
vim.keymap.set("n", "<leader>ll", ":checkhealth vim.lsp<cr>", opts)
