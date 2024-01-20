local parser = require("blame.blame_parser")

---@class BlameViewVirtual : BlameView
---@field config Config
local BlameView = {}

---@param config Config
---@return BlameView
function BlameView:new(config)
    local o = {}
    setmetatable(o, { __index = self })

    o.config = config

    return o
end

---@param porcelain_lines Porcelain[]
function BlameView:open(porcelain_lines)
    local lines = parser.create_lines(porcelain_lines, self.config)

    for _, line in pairs(lines) do
        local is_commited = line.hash.value ~= "0000000"
        if is_commited then
            vim.api.nvim_buf_set_extmark(0, self.config.ns_id, line.idx - 1, 0, {
                virt_text_pos = "right_align",
                virt_text = {
                    { line.author.value, line.author.hl },
                    { line.date.value, line.date.hl },
                    { line.hash.value, line.hash.hl },
                },
            })
        end
    end
end

function BlameView:close()
    vim.api.nvim_buf_clear_namespace(0, self.config.ns_id, 0, -1)
    self.config.ns_id = nil
end

return BlameView
