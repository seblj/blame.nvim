local M = {}

M.original_buffer = nil
M.nsId = nil

---Creates the virtual text floated to theright with the blame lines
---@param blame_lines string[]
---@param config Config
M.virtual_blame = function(blame_lines, config)
    M.original_buffer = vim.api.nvim_win_get_buf(0)
    M.nsId = vim.api.nvim_create_namespace("blame")

    local lines = M.create_lines(blame_lines, config)

    for _, line in pairs(lines) do
        vim.api.nvim_buf_set_extmark(M.original_buffer, M.nsId, line["idx"] - 1, 0, {
            virt_text_pos = "right_align",
            virt_text = {
                { line["author"]["value"], line["author"]["hl"] },
                { line["date"]["value"], line["date"]["hl"] },
                { line["hash"]["value"], line["hash"]["hl"] },
            },
        })
    end
end

M.create_lines = function(blame_lines, config)
    local lines = {}
    for i, value in ipairs(blame_lines) do
        local hash = string.sub(value["hash"], 0, 8)
        local is_commited = hash ~= "00000000"
        if is_commited then
            table.insert(lines, {
                idx = i,
                author = {
                    value = value["author"] .. "  ",
                    hl = hash,
                },
                date = {
                    value = os.date(config.date_format .. "  ", value["committer-time"]),
                    hl = hash,
                },
                hash = {
                    value = hash,
                    hl = "DimHashBlame",
                },
            })
        end
    end
    return lines
end

---Removes the virtual text
M.close_virtual = function()
    vim.api.nvim_buf_clear_namespace(M.original_buffer, M.nsId, 0, -1)
    M.nsId = nil
end

return M
