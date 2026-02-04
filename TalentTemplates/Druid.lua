--[[
Guidelime Vanilla - Talent Templates

Druid talent templates for leveling

Tree Index:
1 = Balance
2 = Feral Combat
3 = Restoration

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Feral Leveling Build (TurtleWoW)
-- https://talents.turtlecraft.gg/druid?points=BgAaAI-FoADBaDQQIFQB-Ao
GLV:RegisterTalentTemplate("DRUID", "Feral", "leveling", {
    [10] = {2, 1, 2},
    [11] = {2, 1, 2},
    [12] = {2, 1, 2},
    [13] = {2, 1, 2},
    [14] = {2, 1, 2},

    [15] = {2, 2, 4},
    [16] = {2, 2, 4},
    [17] = {2, 2, 4},

    [18] = {2, 1, 3},
    [19] = {2, 1, 3},
    [20] = {2, 1, 3},
    [21] = {2, 1, 3},
    [22] = {2, 1, 3},

    [23] = {2, 3, 2},

    [24] = {2, 3, 3},
    [25] = {2, 3, 3},
    [26] = {2, 3, 3},

    [27] = {2, 3, 4},
    [28] = {2, 3, 4},

    [29] = {2, 4, 3},
    [30] = {2, 4, 3},

    [31] = {2, 5, 3},

    [32] = {2, 4, 2},
    [33] = {2, 4, 2},
    [34] = {2, 4, 2},

    [35] = {2, 5, 1},
    [36] = {2, 5, 1},

    [37] = {2, 6, 3},
    [38] = {2, 6, 3},

    [39] = {2, 6, 2},
    [40] = {2, 6, 2},

    [41] = {2, 7, 2},

    [42] = {1, 1, 2},

    [43] = {1, 1, 3},
    [44] = {1, 1, 3},
    [45] = {1, 1, 3},
    [46] = {1, 1, 3},

    [47] = {1, 2, 3},
    [48] = {1, 2, 3},
    [49] = {1, 2, 3},

    [50] = {1, 2, 4},
    [51] = {1, 2, 4},

    [52] = {1, 3, 3},

    [53] = {2, 6, 2},
    [54] = {2, 6, 2},
    [55] = {2, 6, 2},

    [56] = {3, 1, 3},
    [57] = {3, 1, 3},
    [58] = {3, 1, 3},
    [59] = {3, 1, 3},
    [60] = {3, 1, 3},
})

