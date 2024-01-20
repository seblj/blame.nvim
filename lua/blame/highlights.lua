local M = {}

---@return string
local function random_rgb()
    local r = math.random(100, 255)
    local g = math.random(100, 255)
    local b = math.random(100, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

---Highlights each unique hash with a random fg
---@param parsed_lines Porcelain[]
M.map_highlights_per_hash = function(parsed_lines)
    for _, value in ipairs(parsed_lines) do
        local full_hash = value.hash
        local hash = string.sub(full_hash, 0, 7)
        if vim.fn.hlID(hash) == 0 then
            vim.api.nvim_set_hl(0, hash, { fg = random_rgb() })
        end
    end
end

---Applies the created highlights to a specified buffer
---@param lines string[]
---@param config Config
M.highlight_same_hash = function(lines, config)
    for idx, line in ipairs(lines) do
        local hash = line:match("^%S+")
        if hash then
            vim.api.nvim_buf_add_highlight(0, config.ns_id, "Comment", idx - 1, 0, 7)
            vim.api.nvim_buf_add_highlight(0, config.ns_id, hash, idx - 1, 8, -1)
        end
    end
end

return M
