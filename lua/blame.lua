local virtual_blame = require("blame.virtual_blame")
local window_blame = require("blame.window_blame")
local blame_parser = require("blame.blame_parser")
local highlights = require("blame.highlights")
---@class Config
---@field date_format string Format of the output date
---@field merge_consecutive boolean Should same commits be ignored after first line
local config = {
    date_format = "%d.%m.%Y",
}

---@class Blame
---@field config Config
---@field blame_lines table[]
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
    M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

---@param blame_type "window"|"virtual"|""
local function open(blame_type)
    local is_window_open = window_blame.is_window_open()
    local is_virtual_open = virtual_blame.nsId ~= nil

    if is_window_open or is_virtual_open then
        return
    else
        local filename = vim.api.nvim_buf_get_name(0)
        local cwd = vim.fn.expand("%:p:h")

        vim.system({ "git", "--no-pager", "blame", "--line-porcelain", filename }, {
            cwd = cwd,
        }, function(out)
            if out.code ~= 0 then
                vim.notify("Could not execute git blame", vim.log.levels.INFO)
                return
            end

            local output = {}
            local stdout = out.stdout:sub(-1) == "\n" and out.stdout or out.stdout .. "\n"
            for k in stdout:gmatch("([^\n]*)\n") do
                table.insert(output, k)
            end

            vim.schedule(function()
                local parsed_blames = blame_parser.parse_porcelain(output)
                highlights.map_highlights_per_hash(parsed_blames)

                local line_strings = blame_parser.format_blame_to_line_string(parsed_blames, M.config)
                if blame_type == "window" or blame_type == "" then
                    window_blame.window_blame(line_strings, M.config)
                elseif blame_type == "virtual" then
                    virtual_blame.virtual_blame(parsed_blames, M.config)
                end
            end)
        end)
    end
end

local function close()
    local is_window_open = window_blame.is_window_open()
    local is_virtual_open = virtual_blame.nsId ~= nil

    if is_window_open then
        return window_blame.close_window()
    elseif is_virtual_open then
        return virtual_blame.close_virtual()
    end
end

M.toggle = function(arguments)
    local is_window_open = window_blame.is_window_open()
    local is_virtual_open = virtual_blame.nsId ~= nil

    if is_window_open or is_virtual_open then
        return close()
    else
        return open(arguments["args"])
    end
end

M.enable = function(arguments)
    return open(arguments["args"])
end

M.disable = function()
    return close()
end

return M
