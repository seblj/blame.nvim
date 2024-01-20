local parser = require("blame.blame_parser")
local M = {}

---Creates the virtual text floated to theright with the blame lines
---@param blame_lines Porcelain[]
---@param config Config
M.virtual_blame = function(blame_lines, config)
    local lines = parser.create_lines(blame_lines, config)

    for _, line in pairs(lines) do
        local is_commited = line.hash.value ~= "0000000"
        if is_commited then
            vim.api.nvim_buf_set_extmark(0, config.ns_id, line.idx - 1, 0, {
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

return M
