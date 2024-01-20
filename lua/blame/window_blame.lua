local highlights = require("blame.highlights")

---@class BlameViewWindow : BlameView
---@field config Config
---@field blame_window? integer
---@field original_window? integer
local BlameViewWindow = {}

---@param config Config
---@return BlameView
function BlameViewWindow:new(config)
    local o = {}
    setmetatable(o, { __index = self })

    o.config = config
    o.blame_window = nil
    o.original_window = nil

    return o
end

---Sets the autocommands for the blame buffer
---@private
function BlameViewWindow:setup_autocmd()
    vim.api.nvim_create_autocmd({ "BufHidden", "BufUnload" }, {
        callback = function()
            vim.wo[self.original_window][0].cursorbind = false
            vim.wo[self.original_window][0].scrollbind = false
            self.original_window = nil
            self.blame_window = nil
        end,
        buffer = 0,
        group = vim.api.nvim_create_augroup("NvimBlame", { clear = true }),
        desc = "Reset state to closed when the buffer is exited.",
    })
end

local function scroll_to_same_position(win_source, win_target)
    local win_line_source = vim.fn.line("w0", win_source)
    vim.api.nvim_win_set_cursor(win_target, { win_line_source + vim.o.scrolloff, 0 })
    vim.api.nvim_win_call(win_target, function()
        vim.cmd.normal({ "zt", bang = true })
    end)
end

---@param porcelain_lines Porcelain[]
function BlameViewWindow:open(porcelain_lines)
    local blame_lines = vim.iter(porcelain_lines)
        :map(function(v)
            local hash = string.sub(v.hash, 0, 7)
            local is_commited = hash ~= "0000000"
            return is_commited
                    and string.format("%s  %s  %s", hash, os.date(self.config.date_format, v.committer_time), v.author)
                or ""
        end)
        :totable()

    local width = vim.iter(blame_lines):fold(0, function(acc, v)
        return acc < #v and #v or acc
    end) + 7

    self.original_window = vim.api.nvim_get_current_win()

    vim.cmd.vnew({ mods = { split = "aboveleft" } })
    self.blame_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(0, width)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, blame_lines)
    vim.bo.bufhidden = "wipe"
    vim.bo.buftype = "nofile"
    vim.bo.swapfile = false
    vim.bo.modifiable = false
    vim.bo.ft = "blame"
    vim.wo[self.blame_window][0].winbar = vim.wo[self.original_window].winbar

    highlights.highlight_same_hash(blame_lines, self.config)

    scroll_to_same_position(self.original_window, self.blame_window)
    self:setup_autocmd()

    vim.wo[self.original_window][0].scrollbind = true
    vim.wo[self.blame_window][0].scrollbind = true
    vim.wo[self.original_window][0].cursorbind = true
    vim.wo[self.blame_window][0].cursorbind = true

    vim.api.nvim_set_current_win(self.original_window)
end

function BlameViewWindow:close()
    vim.api.nvim_win_close(self.blame_window, true)
end

return BlameViewWindow
