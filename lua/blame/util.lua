local M = {}
M.nsId = nil

M.scroll_to_same_position = function(win_source, win_target)
    local win_line_source = vim.fn.line("w0", win_source)
    local scrolloff = vim.o.scrolloff
    vim.api.nvim_win_set_cursor(win_target, { win_line_source + scrolloff, 0 })
    vim.api.nvim_win_call(win_target, function()
        vim.cmd("normal! zt")
    end)
end

return M
