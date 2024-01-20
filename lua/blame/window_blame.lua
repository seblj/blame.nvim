local util = require("blame.util")
local highlights = require("blame.highlights")
local parser = require("blame.blame_parser")

local M = {}
local blame_window = nil
local original_window = nil

---Sets the autocommands for the blame buffer
local function setup_autocmd()
    vim.api.nvim_create_autocmd({ "BufHidden", "BufUnload" }, {
        callback = function()
            vim.wo[original_window].cursorbind = false
            vim.wo[original_window].scrollbind = false
            original_window = nil
            blame_window = nil
        end,
        buffer = 0,
        group = vim.api.nvim_create_augroup("NvimBlame", { clear = true }),
        desc = "Reset state to closed when the buffer is exited.",
    })
end

---Open window blame
---@param parsed_blames Porcelain[]
---@param config Config
M.window_blame = function(parsed_blames, config)
    local blame_lines = vim.iter(parser.create_lines(parsed_blames, config))
        :map(function(v)
            local is_commited = v.hash.value ~= "0000000"
            return is_commited and string.format("%s %s %s", v.hash.value, v.date.value, v.author.value) or ""
        end)
        :totable()

    local width = vim.iter(blame_lines):fold(0, function(acc, v)
        return acc < #v and #v or acc
    end) + 7

    local winbar = vim.o.winbar
    original_window = vim.api.nvim_get_current_win()

    vim.cmd("lefta vnew")
    blame_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(0, width)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, blame_lines)
    vim.bo.bufhidden = "wipe"
    vim.bo.buftype = "nofile"
    vim.bo.swapfile = false
    vim.bo.modifiable = false
    vim.bo.ft = "blame"
    if winbar ~= "" then
        vim.opt_local.winbar = "%p"
    end
    highlights.highlight_same_hash(0, blame_lines, config)

    util.scroll_to_same_position(original_window, blame_window)
    setup_autocmd()

    for _, option in ipairs({ "cursorbind", "scrollbind" }) do
        vim.api.nvim_set_option_value(option, true, { win = original_window })
        vim.api.nvim_set_option_value(option, true, { win = blame_window })
    end

    vim.api.nvim_set_current_win(original_window)
end

---Close the blame window
M.close_window = function()
    vim.api.nvim_win_close(blame_window, true)
end

M.is_window_open = function()
    return blame_window ~= nil and vim.api.nvim_win_is_valid(blame_window)
end

return M
