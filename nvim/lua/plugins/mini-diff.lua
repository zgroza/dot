-- Define the custom Jujutsu source
local function gen_source_jj()
  local jj_cache = {}

  return {
    name = 'jj',
    attach = function(buf_id)
      local path = vim.api.nvim_buf_get_name(buf_id)
      if path == '' then return false end

      -- 1. Find the jj workspace root
      local buf_dir = vim.fn.fnamemodify(path, ':p:h')
      local root_matches = vim.fs.find('.jj', { path = buf_dir, upward = true, type = 'directory' })
      if not root_matches or #root_matches == 0 then return false end
      local root = vim.fn.fnamemodify(root_matches[1], ':h')

      -- 2. Async helper to get file text at the parent commit (@-)
      local update_ref_text = function()
        -- Note: `vim.system` requires Neovim 0.10+
        vim.system({ 'jj', 'file', 'show', '-r', '@-', path }, { text = true, cwd = root }, function(obj)
          local ref_text = {}
          -- Code 0 means the file exists in the parent commit
          if obj.code == 0 then
            ref_text = vim.split(obj.stdout, '\n')
            -- Remove trailing empty string from the split artifact
            if #ref_text > 0 and ref_text[#ref_text] == '' then
              table.remove(ref_text)
            end
          end

          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf_id) then
              require('mini.diff').set_ref_text(buf_id, ref_text)
            end
          end)
        end)
      end

      -- 3. Initial fetch
      update_ref_text()

      -- 4. Set up an fs watcher on jj's op_heads directory. 
      --    This folder is reliably updated on any jj operation.
      local watch_dir = root .. '/.jj/repo/op_heads'
      local uv = vim.uv or vim.loop
      local w = uv.new_fs_event()
      if w then
        w:start(watch_dir, {}, vim.schedule_wrap(function(err)
          if not err then update_ref_text() end
        end))
      end

      jj_cache[buf_id] = { watcher = w }
      return true
    end,
    detach = function(buf_id)
      local cache = jj_cache[buf_id]
      if cache and cache.watcher then
        cache.watcher:stop()
      end
      jj_cache[buf_id] = nil
    end,
  }
end

return {
  "nvim-mini/mini.diff",
  pin = true,
  version = "*",
  config = function()
    local mini_diff = require('mini.diff')

    mini_diff.setup({
      -- Pass the sources as an array. It will attempt them sequentially.
      -- If it's not a jj workspace, it will instantly fallback to the git source.
      source = {
        gen_source_jj(),
        mini_diff.gen_source.git(),
      },
      view = {
        style = "sign",
      }
    })
  end,
}
