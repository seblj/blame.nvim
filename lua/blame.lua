local virtual_blame = require("blame.virtual_blame")
local window_blame = require("blame.window_blame")
local parser = require("blame.blame_parser")
local highlights = require("blame.highlights")

---@class BlameView
---@field new fun(self, config:Config) : BlameView
---@field open fun(self, lines: Porcelain[])
---@field close fun()

---@class Config
---@field date_format string Format of the output date
local config = {
    date_format = "%d.%m.%Y",
}

---@param blame_view BlameView
local function open(blame_view)
    local filename = vim.api.nvim_buf_get_name(0)
    local cwd = vim.fs.dirname(filename)

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
            blame_view:open(parsed_blames)
        end)
    end)
end

local M = {}

---@param setup_args Config?
M.setup = function(setup_args)
    config = vim.tbl_deep_extend("force", config, setup_args or {})

    local blame = {
        is_open = false,
        blame_view = nil,
        blame_view_virtual = virtual_blame:new(config),
        blame_view_window = window_blame:new(config),
    }

    vim.api.nvim_create_user_command("ToggleBlame", function(args)
        config.ns_id = vim.api.nvim_create_namespace("blame_ns")

        local arg = args["args"]
        if blame.is_open then
            blame.blame_view:close()
            blame.is_open = false
        else
            local blame_view = arg == "virtual" and blame.blame_view_virtual or blame.blame_view_window
            blame.blame_view = blame_view
            open(blame_view)
            blame.is_open = true
        end
    end, {
        nargs = "?",
        complete = function()
            return { "virtual", "window" }
        end,
    })
end

return M
