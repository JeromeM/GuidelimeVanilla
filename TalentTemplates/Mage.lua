--[[
Guidelime Vanilla - Talent Templates

Mage talent templates for leveling

Tree Index:
1 = Arcane
2 = Fire
3 = Frost

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Frost Leveling Build (TurtleWoW)
-- https://talents.turtlecraft.gg/mage?points=TAAo--FYbTpAToBDIAB
GLV:RegisterTalentTemplate("MAGE", "Frost", "leveling", {
    [10] = {3, 1, 2},   -- Improved Frostbolt 1/5
    [11] = {3, 1, 2},   -- Improved Frostbolt 2/5
    [12] = {3, 1, 2},   -- Improved Frostbolt 3/5
    [13] = {3, 1, 2},   -- Improved Frostbolt 4/5
    [14] = {3, 1, 2},   -- Improved Frostbolt 5/5

    [15] = {3, 2, 2},   -- Frostbite 1/3
    [16] = {3, 2, 2},   -- Frostbite 2/3
    [17] = {3, 2, 2},   -- Frostbite 3/3

    [18] = {3, 2, 3},   -- Improved Frost Nova 1/2
    [19] = {3, 2, 3},   -- Improved Frost Nova 2/2

    [20] = {3, 3, 1},   -- Ice Shards 1/5
    [21] = {3, 3, 1},   -- Ice Shards 2/5
    [22] = {3, 3, 1},   -- Ice Shards 3/5
    [23] = {3, 3, 1},   -- Ice Shards 4/5
    [24] = {3, 3, 1},   -- Ice Shards 5/5

    [25] = {3, 4, 3},   -- Shatter 1/5
    [26] = {3, 4, 3},   -- Shatter 2/5
    [27] = {3, 4, 3},   -- Shatter 3/5
    [28] = {3, 4, 3},   -- Shatter 4/5
    [29] = {3, 4, 3},   -- Shatter 5/5

    [30] = {3, 5, 2},   -- Ice Block 1/1

    [31] = {3, 3, 2},   -- Cold Snap 1/1

    [32] = {3, 4, 2},   -- Frost Channeling 1/3
    [33] = {3, 4, 2},   -- Frost Channeling 2/3
    [34] = {3, 4, 2},   -- Frost Channeling 3/3

    [35] = {3, 1, 3},   -- Elemental Precision 1/3
    [36] = {3, 1, 3},   -- Elemental Precision 2/3
    [37] = {3, 1, 3},   -- Elemental Precision 3/3

    [38] = {3, 2, 1},   -- Piercing Ice 1/3
    [39] = {3, 2, 1},   -- Piercing Ice 2/3

    [40] = {3, 7, 2},   -- Ice Barrier 1/1

    [41] = {3, 2, 1},   -- Piercing Ice 3/3

    [42] = {3, 4, 1},   -- Arctic Reach 1/2
    [43] = {3, 4, 1},   -- Arctic Reach 2/2

    [44] = {1, 1, 1},   -- Arcane Subtlety 1/2
    [45] = {1, 1, 1},   -- Arcane Subtlety 2/2

    [46] = {1, 1, 2},   -- Magic Absorption 1/3
    [47] = {1, 1, 2},   -- Magic Absorption 2/3
    [48] = {1, 1, 2},   -- Magic Absorption 3/3

    [49] = {1, 2, 3},   -- Arcane Concentration 1/5
    [50] = {1, 2, 3},   -- Arcane Concentration 2/5
    [51] = {1, 2, 3},   -- Arcane Concentration 3/5
    [52] = {1, 2, 3},   -- Arcane Concentration 4/5
    [53] = {1, 2, 3},   -- Arcane Concentration 5/5

    [54] = {3, 2, 4},   -- Permafrost 1/3
    [55] = {3, 2, 4},   -- Permafrost 2/3
    [56] = {3, 2, 4},   -- Permafrost 3/3

    [57] = {3, 5, 4},   -- Improved Cone of Cold 1/3
    [58] = {3, 5, 4},   -- Improved Cone of Cold 2/3
    [59] = {3, 5, 4},   -- Improved Cone of Cold 3/3

    [60] = {3, 6, 1},   -- Winter's Chill 1/5
})
