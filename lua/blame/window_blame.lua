local util = require("blame.util")
local highlights = require("blame.highlights")

local M = {}
local blame_window = nil
local blame_buffer = nil
local original_window = nil

---Sets the autocommands for the blame buffer
local function setup_autocmd(blame_buff)
    vim.api.nvim_create_autocmd({ "BufHidden", "BufUnload" }, {
        callback = function()
            if blame_buffer ~= nil then
                vim.wo[original_window].cursorbind = false
                vim.wo[original_window].scrollbind = false
                original_window = nil
                blame_window = nil
                blame_buffer = nil
            end
        end,
        buffer = blame_buff,
        group = vim.api.nvim_create_augroup("NvimBlame", { clear = true }),
        desc = "Reset state to closed when the buffer is exited.",
    })
end

---Sets the keybinds for the blame buffer
local function setup_keybinds(buff)
    vim.keymap.set("n", "q", ":q<cr>", { buffer = buff, nowait = true, silent = true })
    vim.keymap.set("n", "<esc>", ":q<cr>", { buffer = buff, nowait = true, silent = true })
    vim.keymap.set("n", "<CR>", function()
        M.show_full_commit()
    end, { buffer = buff, nowait = true, silent = true })
end

---Open window blame
---@param blame_lines any[]
---@param config Config
M.window_blame = function(blame_lines, config)
    local width = vim.iter(blame_lines):fold(0, function(acc, v)
        return acc < #v and #v or acc
    end) + 8

    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    original_window = vim.api.nvim_get_current_win()
    local winbar = vim.o.winbar

    vim.cmd("lefta vs")
    blame_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(blame_window, width)
    blame_buffer = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_win_set_buf(blame_window, blame_buffer)
    vim.api.nvim_buf_set_lines(blame_buffer, 0, -1, false, blame_lines)
    vim.bo[blame_buffer].ft = "blame"
    if winbar ~= "" then
        vim.opt_local.winbar = "%p"
    end

    util.scroll_to_same_position(original_window, blame_window)

    setup_keybinds(blame_buffer)
    setup_autocmd(blame_buffer)

    vim.api.nvim_win_set_cursor(blame_window, cursor_pos)

    for _, option in ipairs({ "cursorbind", "scrollbind" }) do
        vim.api.nvim_set_option_value(option, true, { win = original_window })
        vim.api.nvim_set_option_value(option, true, { win = blame_window })
    end

    vim.api.nvim_set_current_win(original_window)
    highlights.highlight_same_hash(blame_buffer, config.merge_consecutive)
    vim.bo[blame_buffer].modifiable = false
end

---Get git show output for hash under cursor
M.show_full_commit = function()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(blame_window))
    local blame_line = vim.api.nvim_buf_get_lines(blame_buffer, row - 1, row, false)[1]
    local hash = blame_line:match("^%S+")
    -- TODO: Get directory of file in blame
    vim.system({ "git", "show", hash }, {
        cwd = vim.fn.getcwd(original_window),
    }, function(out)
        if out.code ~= 0 then
            return vim.notify("Could not open full commit info", vim.log.levels.INFO)
        end

        local output = {}
        local stdout = out.stdout:sub(-1) == "\n" and out.stdout or out.stdout .. "\n"
        for k in stdout:gmatch("([^\n]*)\n") do
            table.insert(output, k)
        end

        vim.schedule(function()
            local gshow_buff = vim.api.nvim_create_buf(true, true)
            vim.api.nvim_set_current_win(original_window)

            vim.api.nvim_buf_set_lines(gshow_buff, 0, -1, false, output)
            vim.bo[gshow_buff].ft = "git"
            vim.api.nvim_buf_set_name(gshow_buff, hash)
            vim.bo[gshow_buff].readonly = true
            vim.api.nvim_set_current_buf(gshow_buff)
            vim.api.nvim_win_set_buf(original_window, gshow_buff)

            M.close_window()
        end)
    end)
end

---Close the blame window
M.close_window = function()
    local buff = blame_buffer
    vim.api.nvim_win_close(blame_window, true)
    vim.api.nvim_buf_delete(buff, { force = true })
end

M.is_window_open = function()
    return blame_window ~= nil and vim.api.nvim_win_is_valid(blame_window)
end

return M
