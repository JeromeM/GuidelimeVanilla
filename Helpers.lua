--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Helpers and Compat functions
]]--

-- string.gmatch
if not string.gmatch then
    string.gmatch = string.gfind
end

-- table.unpack
if not table.unpack then
    table.unpack = unpack
end

-- string.len
function safe_strlen(str)
    if type(str) == "string" then
        return string.len(str)
    end
    return 0
end

-- secure string.sub
function safe_sub(str, i, j)
    if type(str) ~= "string" then return "" end
    return string.sub(str, i, j)
end

-- naive calculation of the size of a table (only numeric keys)
function safe_tablelen(t)
    if type(t) ~= "table" then return 0 end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) == "number" then
            count = count + 1
        end
    end
    return count
end

-- dump tables
function DumpTable(tbl, indent)
    if not indent then indent = 0 end
    local indentStr = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        local line = indentStr .. tostring(key) .. " = "
        if type(value) == "table" then
            DEFAULT_CHAT_FRAME:AddMessage(line .. "{")
            DumpTable(value, indent + 1)
            DEFAULT_CHAT_FRAME:AddMessage(indentStr .. "}")
        elseif type(value) == "string" then
            local preview = string.sub(value, 1, 100)
            preview = string.gsub(preview, "\n", "\\n")
            DEFAULT_CHAT_FRAME:AddMessage(line .. '"' .. preview .. '"...')
        else
            DEFAULT_CHAT_FRAME:AddMessage(line .. tostring(value))
        end
    end
end