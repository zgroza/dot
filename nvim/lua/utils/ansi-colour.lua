-- ANSI color to Hex mapping (standard 16 colors)
local fg_colors = {
    [30] = "#000000", [31] = "#cd3131", [32] = "#0dbc79", [33] = "#e5e510",
    [34] = "#2472c8", [35] = "#bc3fbc", [36] = "#11a8cd", [37] = "#e5e5e5",
    [90] = "#666666", [91] = "#f14c4c", [92] = "#23d18b", [93] = "#f5f543",
    [94] = "#3b8eea", [95] = "#d670d6", [96] = "#29b8db", [97] = "#e5e5e5",
}

local bg_colors = {
    [40] = "#000000", [41] = "#cd3131", [42] = "#0dbc79", [43] = "#e5e510",
    [44] = "#2472c8", [45] = "#bc3fbc", [46] = "#11a8cd", [47] = "#e5e5e5",
}

local standard_colors = {
    [0] = "#000000", [1] = "#cd3131", [2] = "#0dbc79", [3] = "#e5e510",
    [4] = "#2472c8", [5] = "#bc3fbc", [6] = "#11a8cd", [7] = "#e5e5e5",
    [8] = "#666666", [9] = "#f14c4c", [10] = "#23d18b", [11] = "#f5f543",
    [12] = "#3b8eea", [13] = "#d670d6", [14] = "#29b8db", [15] = "#e5e5e5",
}

local function get_256_color(n)
    if not n then return nil end
    if n >= 0 and n <= 15 then
        return standard_colors[n]
    elseif n >= 16 and n <= 231 then
        n = n - 16
        local r = math.floor(n / 36)
        local g = math.floor((n % 36) / 6)
        local b = n % 6
        local map = {[0]=0, [1]=95, [2]=135, [3]=175, [4]=215, [5]=255}
        return string.format("#%02x%02x%02x", map[r], map[g], map[b])
    elseif n >= 232 and n <= 255 then
        local gray = 8 + (n - 232) * 10
        return string.format("#%02x%02x%02x", gray, gray, gray)
    end
    return nil
end

local hl_cache = {}
local hl_ns = vim.api.nvim_create_namespace("AnsiColors")
local meta_ns = vim.api.nvim_create_namespace("AnsiMeta")
-- Persistent storage for ANSI codes, indexed by bufnr and extmark ID
local ansi_codes_storage = {}

local function toggle_ansi_colors(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    local was_modifiable = vim.bo[bufnr].modifiable
    local was_modified = vim.bo[bufnr].modified
    local was_readonly = vim.bo[bufnr].readonly
    
    -- If already colorized, reconstruct the original buffer content
    if vim.b[bufnr].is_ansi_colorized then
        local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local restored_lines = {}
        local buf_codes = ansi_codes_storage[bufnr] or {}

        for i, line in ipairs(current_lines) do
            local marks = vim.api.nvim_buf_get_extmarks(bufnr, meta_ns, {i-1, 0}, {i-1, -1}, { details = true })
            -- Sort by column descending to insert from end to start
            table.sort(marks, function(a, b) 
                if a[3] ~= b[3] then return a[3] > b[3] end
                return a[1] > b[1]
            end)
            
            local restored = line
            for _, mark in ipairs(marks) do
                local code = buf_codes[mark[1]]
                if code then
                    restored = string.sub(restored, 1, mark[3]) .. code .. string.sub(restored, mark[3] + 1)
                end
            end
            table.insert(restored_lines, restored)
        end
        
        vim.bo[bufnr].readonly = false
        vim.bo[bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, restored_lines)
        vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(bufnr, meta_ns, 0, -1)
        
        vim.bo[bufnr].modifiable = was_modifiable
        vim.bo[bufnr].modified = was_modified
        vim.bo[bufnr].readonly = was_readonly
        
        ansi_codes_storage[bufnr] = nil
        vim.b[bufnr].is_ansi_colorized = false
        return
    end

    -- Colorize: Strip codes and store as metadata
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local stripped_lines = {}
    local hl_marks = {}
    local meta_marks = {}
    local active_hl = {}

    local function get_hl_group()
        if not active_hl.fg and not active_hl.bg and not active_hl.bold and not active_hl.underline then return nil end
        local fg_n = (active_hl.fg or "N"):gsub("#", "")
        local bg_n = (active_hl.bg or "N"):gsub("#", "")
        local hl_name = "Ansi_" .. fg_n .. "_" .. bg_n .. (active_hl.bold and "_B" or "") .. (active_hl.underline and "_U" or "")
        if not hl_cache[hl_name] then
            vim.api.nvim_set_hl(0, hl_name, { fg = active_hl.fg, bg = active_hl.bg, bold = active_hl.bold, underline = active_hl.underline })
            hl_cache[hl_name] = true
        end
        return hl_name
    end

    for i, line in ipairs(lines) do
        local last_idx = 1
        local stripped = ""
        local current_col = 0
        
        while true do
            local s, e, codes, letter = string.find(line, "\27%[([0-9;]*)([a-zA-Z])", last_idx)
            
            local text_segment = string.sub(line, last_idx, (s or 0) - 1)
            if #text_segment > 0 then
                local group = get_hl_group()
                if group then table.insert(hl_marks, { i - 1, current_col, current_col + #text_segment, group }) end
                stripped = stripped .. text_segment
                current_col = current_col + #text_segment
            end
            
            if not s then break end
            
            table.insert(meta_marks, { i - 1, current_col, string.sub(line, s, e) })

            if letter == "m" then
                if codes == "" or codes == "0" then active_hl = {}
                else
                    local c_arr = {}
                    for c in string.gmatch(codes, "[^;]+") do table.insert(c_arr, tonumber(c)) end
                    local idx = 1
                    while idx <= #c_arr do
                        local code = c_arr[idx]
                        if code == 0 then active_hl = {}
                        elseif code == 1 then active_hl.bold = true
                        elseif code == 4 then active_hl.underline = true
                        elseif code == 22 then active_hl.bold = false
                        elseif code == 24 then active_hl.underline = false
                        elseif code == 39 then active_hl.fg = nil
                        elseif code == 49 then active_hl.bg = nil
                        elseif fg_colors[code] then active_hl.fg = fg_colors[code]
                        elseif bg_colors[code] then active_hl.bg = bg_colors[code]
                        elseif code == 38 and c_arr[idx+1] == 5 and c_arr[idx+2] then
                            active_hl.fg = get_256_color(c_arr[idx+2]); idx = idx + 2
                        elseif code == 48 and c_arr[idx+1] == 5 and c_arr[idx+2] then
                            active_hl.bg = get_256_color(c_arr[idx+2]); idx = idx + 2
                        elseif code == 38 and c_arr[idx+1] == 2 and c_arr[idx+4] then
                            active_hl.fg = string.format("#%02x%02x%02x", c_arr[idx+2], c_arr[idx+3], c_arr[idx+4]); idx = idx + 4
                        elseif code == 48 and c_arr[idx+1] == 2 and c_arr[idx+4] then
                            active_hl.bg = string.format("#%02x%02x%02x", c_arr[idx+2], c_arr[idx+3], c_arr[idx+4]); idx = idx + 4
                        end
                        idx = idx + 1
                    end
                end
            end
            last_idx = e + 1
        end
        table.insert(stripped_lines, stripped)
    end

    vim.bo[bufnr].readonly = false
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, stripped_lines)
    
    ansi_codes_storage[bufnr] = {}
    for _, m in ipairs(meta_marks) do
        local id = vim.api.nvim_buf_set_extmark(bufnr, meta_ns, m[1], m[2], { right_gravity = false })
        ansi_codes_storage[bufnr][id] = m[3]
    end
    for _, m in ipairs(hl_marks) do
        vim.api.nvim_buf_set_extmark(bufnr, hl_ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
    end

    vim.bo[bufnr].modifiable = was_modifiable
    vim.bo[bufnr].modified = was_modified
    vim.bo[bufnr].readonly = was_readonly
    vim.b[bufnr].is_ansi_colorized = true
end

-- Yank handler
local function clean_yank()
    local event = vim.v.event
    if event.operator == 'y' or event.operator == 'd' then
        local reg = event.regname == "" and '"' or event.regname
        local content = vim.fn.getreg(reg, 1, true)
        if type(content) == "table" then
            local stripped = {}
            for _, line in ipairs(content) do
                table.insert(stripped, (line:gsub('\27%[[0-9;]*[a-zA-Z]', '')))
            end
            vim.fn.setreg(reg, stripped, event.regtype)
        end
    end
end

vim.keymap.set('n', '<leader>co', function() toggle_ansi_colors() end, { desc = "Toggle ANSI colors", noremap = true, silent = true })

local auto_ansi_group = vim.api.nvim_create_augroup("AutoAnsiColorize", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "StdinReadPost" }, {
    group = auto_ansi_group,
    callback = function(args)
        local bufnr = args.buf
        if vim.bo[bufnr].buftype == "terminal" or vim.b[bufnr].is_ansi_colorized then return end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
        for _, line in ipairs(lines) do
            if string.find(line, "\27%[") then
                vim.schedule(function() if vim.api.nvim_buf_is_valid(bufnr) then toggle_ansi_colors(bufnr) end end)
                break
            end
        end
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", { group = auto_ansi_group, callback = clean_yank })

-- Handle saving
vim.api.nvim_create_autocmd("BufWritePre", {
    group = auto_ansi_group,
    callback = function(args)
        if vim.b[args.buf].is_ansi_colorized then
            toggle_ansi_colors(args.buf)
            vim.b[args.buf].should_recolorize = true
        end
    end,
})
vim.api.nvim_create_autocmd("BufWritePost", {
    group = auto_ansi_group,
    callback = function(args)
        if vim.b[args.buf].should_recolorize then
            toggle_ansi_colors(args.buf)
            vim.b[args.buf].should_recolorize = nil
        end
    end,
})
