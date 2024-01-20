---@class BlameViewVirtual : BlameView
---@field config Config
local BlameViewVirtual = {}

---@param config Config
---@return BlameView
function BlameViewVirtual:new(config)
    local o = {}
    setmetatable(o, { __index = self })

    o.config = config

    return o
end

---@param lines Porcelain[]
function BlameViewVirtual:open(lines)
    for idx, line in pairs(lines) do
        local hash = string.sub(line.hash, 0, 7)
        local is_commited = hash ~= "0000000"
        if is_commited then
            vim.api.nvim_buf_set_extmark(0, self.config.ns_id, idx - 1, 0, {
                virt_text_pos = "right_align",
                virt_text = {
                    { line.author .. "  ", hash },
                    { os.date(self.config.date_format, line.committer_time) .. "  ", hash },
                    { hash, "Comment" },
                },
            })
        end
    end
end

function BlameViewVirtual:close()
    vim.api.nvim_buf_clear_namespace(0, self.config.ns_id, 0, -1)
    self.config.ns_id = nil
end

return BlameViewVirtual
