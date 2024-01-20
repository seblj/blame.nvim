local virtual_blame = require("blame.virtual_blame")
local window_blame = require("blame.window_blame")
local parser = require("blame.blame_parser")
local highlights = require("blame.highlights")

---@class BlameView
---@field new fun(self, config:Config) : BlameView
---@field open fun(self, lines: Porcelain[])
---@field close fun()

---@class Config
---@field date_format? string Format of the output date
---@field views table<string, BlameView>
local config = {
    date_format = "%d.%m.%Y",
    views = {
        default = window_blame,
        window = window_blame,
        virtual = virtual_blame,
    },
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

---@param setup_args Config | nil
M.setup = function(setup_args)
    config = vim.tbl_deep_extend("force", config, setup_args or {})

    local blame_view = config.views.default:new(config)
    local is_open = false

    vim.api.nvim_create_user_command("ToggleBlame", function(args)
        config.ns_id = vim.api.nvim_create_namespace("blame_ns")

        if is_open then
            blame_view:close()
            is_open = false
        else
            local arg = args.args == "" and "default" or args.args
            blame_view = config.views[arg]:new(config)
            open(blame_view)
            is_open = true
        end
    end, {
        nargs = "?",
        complete = function()
            return vim.iter.filter(function(v)
                return v ~= "default"
            end, vim.tbl_keys(config.views))
        end,
    })
end

return M
