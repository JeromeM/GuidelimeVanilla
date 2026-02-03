--[[
Guidelime Vanilla - Talent Templates

Warrior talent templates for leveling

Tree Index:
1 = Arms
2 = Fury
3 = Protection

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Arms Leveling Build
GLV:RegisterTalentTemplate("WARRIOR", "Arms", "leveling", {
    -- TODO: Fill with TurtleWoW talent positions
    -- [10] = {1, 1, 1},  -- Example: First talent in Arms tree
})

-- Fury Leveling Build
GLV:RegisterTalentTemplate("WARRIOR", "Fury", "leveling", {
    -- TODO: Fill with TurtleWoW talent positions
})

-- Protection Leveling Build
GLV:RegisterTalentTemplate("WARRIOR", "Protection", "leveling", {
    -- TODO: Fill with TurtleWoW talent positions
})
