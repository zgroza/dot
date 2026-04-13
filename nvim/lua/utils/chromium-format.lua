local function apply_minimal_changes(bufnr, new_lines)
  local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local old_text = table.concat(old_lines, "\n")
  local new_text = table.concat(new_lines, "\n")

  if old_text == new_text then return false end

  local hunks = vim.diff(old_text, new_text, { result_type = "indices", algorithm = "histogram", })
  if not hunks or #hunks == 0 then return false end

  for i = #hunks, 1, -1 do
    local hunk = hunks[i]
    local start_a, count_a, start_b, count_b = hunk[1], hunk[2], hunk[3], hunk[4]

    local replacement_lines = {}
    if count_b > 0 then
      for j = 0, count_b - 1 do
        table.insert(replacement_lines, new_lines[start_b + j])
      end
    end

    local start_row = start_a - 1
    local end_row = start_row + count_a
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, replacement_lines)
  end

  return true
end

local function setup_git_cl_format()
  local current_dir = vim.fn.getcwd()
  -- Ensure we are in chromium src before setting up the autocmd
  if string.find(current_dir, vim.fn.expand("~/chromium/src"), 1, true) ~= 1 then return end

  local augroup = vim.api.nvim_create_augroup("ClFormatGroup", { clear = true, })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*",
    callback = function(args)
      -- 1. Guard Clauses
      if vim.b[args.buf].git_cl_formatting then return end

      -- Ignore special buffers (terminals, NvimTree, help, etc.)
      if vim.bo[args.buf].buftype ~= "" then return end

      local filepath = vim.api.nvim_buf_get_name(args.buf)

      -- Ignore files outside the chromium src tree
      if string.find(filepath, vim.fn.expand("~/chromium/src"), 1, true) ~= 1 then return end

      -- 2. Setup Temp File
      local temp_path = vim.fn.tempname()
      local current_content = vim.fn.readfile(filepath)
      vim.fn.writefile(current_content, temp_path)

      -- 3. Execute Pipeline
      -- If git cl format doesn't support the file type, it outputs nothing.
      -- Patch with empty input does nothing. Safe for all files.
      local cmd = string.format(
        "git cl format --diff %s | patch --quiet %s",
        vim.fn.shellescape(filepath),
        vim.fn.shellescape(temp_path)
      )

      local output = vim.fn.system(cmd)
      local exit_code = vim.v.shell_error

      -- 4. Error Handling
      if exit_code > 1 then
        -- exit_code 1 is "diffs found" (sometimes dependent on patch version), >1 is error
        vim.notify("Git cl format failed: " .. output, vim.log.levels.ERROR)
        vim.fn.delete(temp_path)
        return
      end

      -- 5. Apply Changes
      local new_lines = vim.fn.readfile(temp_path)
      vim.fn.delete(temp_path)

      vim.api.nvim_buf_call(args.buf, function()
        vim.b[args.buf].git_cl_formatting = true

        local changed = apply_minimal_changes(args.buf, new_lines)

        if changed then
          vim.cmd("noautocmd write")
          -- Optional: print message only if things actually changed
          -- print("Formatted: " .. vim.fn.fnamemodify(filepath, ":t"))
        end

        vim.b[args.buf].git_cl_formatting = false
      end)
    end,
  })
end

setup_git_cl_format()
