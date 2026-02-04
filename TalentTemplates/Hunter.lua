--[[
Guidelime Vanilla - Talent Templates

Hunter talent templates for leveling

Tree Index:
1 = Beast Mastery
2 = Marksmanship
3 = Survival

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Beast Mastery Leveling Build (TurtleWoW)
-- https://talents.turtlecraft.gg/hunter?points=FQAYBoBoBCQYB-AoCoQBAo-
GLV:RegisterTalentTemplate("HUNTER", "Beast Mastery", "leveling", {
    [10] = {2, 1, 3},
    [11] = {2, 1, 3},
    [12] = {2, 1, 3},
    [13] = {2, 1, 3},
    [14] = {2, 1, 3},

    [15] = {2, 2, 3},
    [16] = {2, 2, 3},
    [17] = {2, 2, 3},
    [18] = {2, 2, 3},
    [19] = {2, 2, 3},

    [20] = {2, 3, 4},

    [21] = {1, 1, 2},
    [22] = {1, 1, 2},
    [23] = {1, 1, 2},
    [24] = {1, 1, 2},
    [25] = {1, 1, 2},

    [26] = {1, 2, 3},
    [27] = {1, 2, 3},
    [28] = {1, 2, 3},

    [29] = {1, 1, 3},
    [30] = {1, 1, 3},

    [31] = {1, 3, 2},

    [32] = {1, 3, 3},
    [33] = {1, 3, 3},
    [34] = {1, 3, 3},
    [35] = {1, 3, 3},
    [36] = {1, 3, 3},

    [37] = {1, 4, 3},
    [38] = {1, 4, 3},
    [39] = {1, 4, 3},
    [40] = {1, 4, 3},

    [41] = {1, 5, 2},

    [42] = {1, 5, 4},
    [43] = {1, 5, 4},

    [44] = {1, 4, 3},

    [45] = {1, 4, 2},

    [46] = {1, 6, 2},
    [47] = {1, 6, 2},

    [48] = {1, 6, 3},
    [49] = {1, 6, 3},
    [50] = {1, 6, 3},

    [51] = {1, 7, 2},

    [52] = {2, 3, 1},
    [53] = {2, 3, 1},

    [54] = {2, 2, 2},
    [55] = {2, 2, 2},

    [56] = {2, 4, 3},
    [57] = {2, 4, 3},
    [58] = {2, 4, 3},
    [59] = {2, 4, 3},
    [60] = {2, 4, 3},
})
