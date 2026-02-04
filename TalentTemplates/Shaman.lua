--[[
Guidelime Vanilla - Talent Templates

Shaman talent templates for leveling

Tree Index:
1 = Elemental
2 = Enhancement
3 = Restoration

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Enhancement Leveling Build (TurtleWoW)
-- https://talents.turtlecraft.gg/shaman?points=FYAYL-AoVYALFQDIAoB-
GLV:RegisterTalentTemplate("SHAMAN", "Enhancement", "leveling", {
    [10] = {2, 1, 3},
    [11] = {2, 1, 3},
    [12] = {2, 1, 3},
    [13] = {2, 1, 3},
    [14] = {2, 1, 3},

    [15] = {2, 2, 1},
    [16] = {2, 2, 1},

    [17] = {2, 2, 3},
    [18] = {2, 2, 3},
    [19] = {2, 2, 3},

    [20] = {2, 3, 4},
    [21] = {2, 3, 4},
    [22] = {2, 3, 4},

    [23] = {2, 3, 3},

    [24] = {2, 2, 2},

    [25] = {2, 4, 3},
    [26] = {2, 4, 3},

    [27] = {2, 2, 2},
    [28] = {2, 2, 2},
    [29] = {2, 2, 2},

    [30] = {2, 5, 2},
    [31] = {2, 5, 2},
    [32] = {2, 5, 2},

    [33] = {2, 5, 3},

    [34] = {1, 1, 2},
    [35] = {1, 1, 2},
    [36] = {1, 1, 2},
    [37] = {1, 1, 2},
    [38] = {1, 1, 2},

    [39] = {1, 1, 3},
    [40] = {1, 1, 3},

    [41] = {1, 2, 3},
    [42] = {1, 2, 3},
    [43] = {1, 2, 3},

    [44] = {1, 3, 1},

    [45] = {2, 2, 2},

    [46] = {2, 6, 3},
    [47] = {2, 6, 3},
    [48] = {2, 6, 3},
    [49] = {2, 6, 3},
    [50] = {2, 6, 3},

    [51] = {2, 7, 2},

    [52] = {1, 3, 2},
    [53] = {1, 3, 2},
    [54] = {1, 3, 2},

    [55] = {2, 4, 2},
    [56] = {2, 4, 2},
    [57] = {2, 4, 2},
    [58] = {2, 4, 2},
    [59] = {2, 4, 2},

    [60] = {1, 1, 3},
})
