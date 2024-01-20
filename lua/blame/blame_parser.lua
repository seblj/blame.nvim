local M = {}

---@class Porcelain
---@field author string
---@field author_email string
---@field author_time string
---@field author_tz string
---@field committer string
---@field committer_mail string
---@field committer_time string
---@field committer_tz string
---@field filename string
---@field hash string
---@field previous string
---@field summary string
---@field content string

---Parses raw porcelain data (string[]) into an array of tables for each line containing the commit data
---@param blame_porcelain string[]
---@return Porcelain[]
M.parse_porcelain = function(blame_porcelain)
    local all_lines = {}
    for _, entry in ipairs(blame_porcelain) do
        local ident = entry:match("^%S+")
        if not ident then
            all_lines[#all_lines].content = entry
        elseif #ident == 40 then
            table.insert(all_lines, { hash = ident })
        else
            ident = ident:gsub("-", "_")
            all_lines[#all_lines][ident] = string.sub(entry, #ident + 2, -1)
        end
    end
    return all_lines
end

---@class BlameLineField
---@field value string
---@field hl string

---@class BlameLine
---@field idx number
---@field author BlameLineField
---@field date BlameLineField
---@field hash BlameLineField

---@param blame_lines Porcelain[]
---@return BlameLine[]
M.create_lines = function(blame_lines, config)
    return vim.iter(blame_lines)
        :enumerate()
        :map(function(i, v)
            local hash = string.sub(v.hash, 0, 7)
            return {
                idx = i,
                author = {
                    value = v.author .. "  ",
                    hl = hash,
                },
                date = {
                    ---@diagnostic disable-next-line: param-type-mismatch
                    value = os.date(config.date_format .. "  ", v.committer_time),
                    hl = hash,
                },
                hash = {
                    value = hash,
                    hl = "Comment",
                },
            }
        end)
        :totable()
end

return M
