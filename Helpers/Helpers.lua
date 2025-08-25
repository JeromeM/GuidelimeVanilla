--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Helpers and Compat functions
]]--
local GLV = LibStub("GuidelimeVanilla")


function GetPlayerFacing()
	local p = Minimap
	local m = ({p:GetChildren()})[9]
	return m:GetFacing()
end

-- string.gmatch
if not string.gmatch then
    string.gmatch = string.gfind
end

-- string.match
if type(string.match) ~= "function" then
    string.match = function(s, pattern)
        local i1, i2, c1, c2, c3, c4, c5, c6, c7, c8, c9 = string.find(s, pattern)
        return c1, c2, c3, c4, c5, c6, c7, c8, c9
    end
end

-- table.unpack
if not table.unpack then
    table.unpack = unpack
end

-- Get safe string length with type checking
function safe_strlen(str)
    if type(str) == "string" then
        return string.len(str)
    end
    return 0
end

-- Get safe string substring with type checking
function safe_sub(str, i, j)
    if type(str) ~= "string" then return "" end
    return string.sub(str, i, j)
end

-- Get safe table length counting only numeric keys
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

-- Remove leading and trailing whitespace from string
function trim(str)
    if type(str) ~= "string" then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

-- Debug function to dump table contents to chat
function DumpTable(tbl, indent)
    if not indent then indent = 0 end
    local indentStr = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        local line = indentStr .. tostring(key) .. " = "
        if type(value) == "table" then
            if GLV and GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage(line .. "{")
            end
            DumpTable(value, indent + 1)
            if GLV and GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage(indentStr .. "}")
            end
        elseif type(value) == "string" then
            local preview = string.sub(value, 1, 100)
            preview = string.gsub(preview, "\n", "\\n")
            if GLV and GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage(line .. '"' .. preview .. '"...')
            end
        else
            if GLV and GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage(line .. tostring(value))
            end
        end
    end
end

-- Check if a number is even
function isEven(n)
    return n / 2 == math.floor(n / 2)
end

-- Calculate modulo operation
function modulo(val, by)
    return val - math.floor(val/by)*by;
end