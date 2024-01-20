local virtual_blame = require("blame.virtual_blame")
local window_blame = require("blame.window_blame")
local parser = require("blame.blame_parser")
local highlights = require("blame.highlights")

---@class Config
---@field date_format string Format of the output date
local config = {
    date_format = "%d.%m.%Y",
}

local virtual_blame_open = false

---@class Blame
---@field config Config
local M = {}

---@param args Config?
M.setup = function(args)
    M.config = vim.tbl_deep_extend("force", config, args or {})
end

---@param blame_type "window"|"virtual"|""
local function open(blame_type)
    local filename = vim.api.nvim_buf_get_name(0)
    local cwd = vim.fn.expand("%:p:h")

    vim.system({ "git", "--no-pager", "blame", "--line-porcelain", filename }, {
        cwd = cwd,
    }, function(out)
        if out.code ~= 0 then
            return vim.notify("Could not execute git blame")
        end

        local output = {}
        local stdout = out.stdout:sub(-1) == "\n" and out.stdout or out.stdout .. "\n"
        for k in stdout:gmatch("([^\n]*)\n") do
            table.insert(output, k)
        end

        vim.schedule(function()
            local parsed_blames = parser.parse_porcelain(output)
            highlights.map_highlights_per_hash(parsed_blames)

            if blame_type == "window" or blame_type == "" then
                window_blame.window_blame(parsed_blames, config)
            elseif blame_type == "virtual" then
                virtual_blame.virtual_blame(parsed_blames, config)
                virtual_blame_open = true
            end
        end)
    end)
end

vim.api.nvim_create_user_command("ToggleBlame", function(args)
    local is_window_open = window_blame.is_window_open()
    local arg = args["args"]
    config.ns_id = vim.api.nvim_create_namespace("blame_ns")

    if is_window_open then
        window_blame.close_window()
        config.ns_id = nil
    elseif virtual_blame_open then
        virtual_blame_open = false
        vim.api.nvim_buf_clear_namespace(0, config.ns_id, 0, -1)
        config.ns_id = nil
    else
        return open(arg)
    end
end, {
    nargs = "?",
    complete = function()
        return { "virtual", "window" }
    end,
})

return M
