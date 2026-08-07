-- Context-aware hover framework: picks a provider based on what's under the
-- cursor and lets you cycle between them.
--
-- Note: upstream's default provider list also includes
-- `hover.providers.dictionary`, which shells out to `curl` and sends the word
-- under the cursor to api.dictionaryapi.dev. Providers are listed explicitly
-- below so that never gets pulled in.
return {
  "lewis6991/hover.nvim",
  pin = true,
  event = "VeryLazy",
  config = function()
    local hover = require("hover")

    local OPEN_DELAY = 500 -- ms the pointer must rest before the window opens
    local CLOSE_DELAY = 50 -- ms before it retracts once the pointer leaves
    local MOUSE_PROVIDERS = { "hover.providers.diagnostic", "hover.providers.lsp", }

    hover.config({
      providers = {
        "hover.providers.diagnostic",
        "hover.providers.lsp",
        "hover.providers.man",
      },
      -- Only read by `hover.mouse()`, which mouse_hover() below replaces; kept
      -- in sync so both paths behave the same.
      mouse_providers = MOUSE_PROVIDERS,
      mouse_delay = OPEN_DELAY,
      preview_opts = { border = "rounded", }, -- matches vim.opt.winborder
      preview_window = false,
      title = true,
    })

    -- `hover.switch` is a no-op when no hover window is open, but the mapping
    -- would still swallow the key. Fall back to the default motion instead.
    local function switch(direction, fallback)
      return function()
        local win = vim.b.hover_preview
        if not (win and vim.api.nvim_win_is_valid(win)) then
          return fallback
        end
        hover.switch(direction)
      end
    end

    vim.keymap.set("n", "K", hover.open, { desc = "Hover (open)", })
    vim.keymap.set("n", "gK", hover.enter, { desc = "Hover (enter window)", })
    vim.keymap.set("n", "<leader>hs", hover.select, { desc = "Hover (select source)", })
    vim.keymap.set("n", "<C-n>", switch("next", "<C-n>"),
                   { expr = true, desc = "Hover (next source)", })
    vim.keymap.set("n", "<C-p>", switch("previous", "<C-p>"),
                   { expr = true, desc = "Hover (previous source)", })

    -- Mouse integration (needs vim.opt.mousemoveevent, see core/options.lua).
    --
    -- This replaces `hover.mouse()` rather than wrapping it, for three reasons:
    -- it only checks the pointer is over *a window*, so statuslines and blank
    -- space past the end of a line still fire hovers; `hover.open()` renders a
    -- "No result" placeholder whenever providers come back empty, so those
    -- bogus positions leave stray windows behind; and its single timer can't
    -- give opening and retracting different delays.

    --- The pointer's position, when it's resting on something hoverable.
    --- @return integer? buf, table? pos, boolean? on_float
    local function mouse_target()
      local pos = vim.fn.getmousepos()
      if pos.winid == 0 then
        return
      end
      -- A float, most likely our own hover window: leave it be so the pointer
      -- can travel into it.
      if vim.api.nvim_win_get_config(pos.winid).relative ~= "" then
        return nil, nil, true
      end
      local buf = vim.fn.winbufnr(pos.winid)
      -- `line` is 0 on statuslines and vertical separators.
      if pos.line == 0 or buf == -1 then
        return
      end
      local line = vim.api.nvim_buf_get_lines(buf, pos.line - 1, pos.line, false)[1]
      if not line then
        return -- below the last line of the buffer
      end
      -- `column` is a 1-based byte index, and #line + 1 past the end of text.
      local char = line:sub(pos.column, pos.column)
      if char == "" or char:match("%s") then
        return -- past the end of the line, or over indentation
      end
      return buf, pos
    end

    --- Does any server have hover content at this position? Servers answer
    --- `result: null` over comments, keywords and literals, which hover.nvim
    --- turns into its own "No result" window; asking first lets us not open
    --- one. Costs a second textDocument/hover (the provider repeats it once we
    --- call open) but it is cheap, idempotent, and only fires once the pointer
    --- has settled.
    --- @param cb fun(has_content: boolean)
    local function probe(buf, row, col, cb)
      if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/hover", })) then
        return cb(false) -- buf_request_all never calls back with no clients
      end
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      vim.lsp.buf_request_all(buf, "textDocument/hover", function(client)
        return {
          textDocument = { uri = vim.uri_from_bufnr(buf), },
          position = {
            line = row,
            character = vim.str_utfindex(line, client.offset_encoding, math.min(col, #line)),
          },
        }
      end, function(results)
        for _, r in pairs(results) do
          local contents = r.result and r.result.contents
          -- Blank contents count as absent: some servers answer with an empty
          -- string rather than null, which would render as an empty window.
          for _, l in ipairs(contents and vim.lsp.util.convert_input_to_markdown_lines(contents) or {}) do
            if l:match("%S") then
              return cb(true)
            end
          end
        end
        cb(false)
      end)
    end

    local open_timer = assert(vim.uv.new_timer())
    local close_timer = assert(vim.uv.new_timer())
    local shown = nil -- position the visible window was opened for
    local generation = 0 -- invalidates an in-flight probe once the pointer moves

    -- Mouse motion never fires CursorMoved, so nothing else would take the
    -- window down while the cursor sits still.
    local function retract()
      if shown and vim.api.nvim_buf_is_valid(shown.buf) then
        hover.close(shown.buf)
      end
      shown = nil
    end

    -- Deciding *whether* to hover is cheap (no requests), so it runs on every
    -- MouseMove and only the open and the retract are debounced. That lets the
    -- two use separate delays: slow to appear, quick to get out of the way.
    local function mouse_hover()
      local buf, pos, on_float = mouse_target()
      if on_float then
        open_timer:stop()
        close_timer:stop()
        return
      end

      -- Already showing exactly this: cancel any pending transition and don't
      -- re-probe on pointer jitter.
      if
        shown
        and buf
        and shown.buf == buf
        and shown.line == pos.line
        and shown.column == pos.column
      then
        open_timer:stop()
        close_timer:stop()
        return
      end

      -- The situation changed: drop a pending open and orphan any in-flight probe.
      open_timer:stop()
      generation = generation + 1
      local gen = generation

      -- Retract on the short delay, whether the pointer left the text entirely
      -- or moved to a target whose content may not even arrive.
      close_timer:stop()
      if shown then
        close_timer:start(CLOSE_DELAY, 0, vim.schedule_wrap(retract))
      end

      if not buf then
        return
      end

      open_timer:start(OPEN_DELAY, 0, vim.schedule_wrap(function()
        -- `create_params` in the LSP provider reads pos[2] as a 0-based byte
        -- offset -- correct for the keymap path, which feeds it
        -- nvim_win_get_cursor -- but getmousepos().column is 1-based. Passing
        -- it straight through queries one byte right of the pointer, landing on
        -- the following space at the end of a token. Use cursor semantics.
        local row, col = pos.line - 1, pos.column - 1

        local function show()
          if gen ~= generation then
            return -- pointer moved on while we were asking
          end
          shown = { buf = buf, line = pos.line, column = pos.column, }
          hover.open({
            providers = MOUSE_PROVIDERS,
            relative = "mouse",
            pos = { pos.line, col, },
            bufnr = buf,
          })
        end

        -- A diagnostic on the line is enough on its own; otherwise only open if
        -- a server actually has something to say here.
        if not vim.tbl_isempty(vim.diagnostic.get(buf, { lnum = row, })) then
          show()
        else
          probe(buf, row, col, function(has_content)
            if has_content then
              show()
            end
          end)
        end
      end))
    end

    vim.keymap.set("n", "<MouseMove>", mouse_hover, { desc = "Hover (mouse)", })
  end,
}
