--[[
Guidelime Vanilla - Talent Templates

Warlock talent templates for leveling

Tree Index:
1 = Affliction
2 = Demonology
3 = Destruction

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Affliction Leveling Build (TurtleWoW)
GLV:RegisterTalentTemplate("WARLOCK", "Affliction", "leveling", {
    [10] = {1, 1, 3},
    [11] = {1, 1, 3},
    [12] = {1, 1, 3},
    [13] = {1, 1, 3},
    [14] = {1, 1, 3},

    [15] = {1, 2, 3},
    [16] = {1, 2, 3},

    [17] = {1, 2, 4},
    [18] = {1, 2, 4},

    [19] = {1, 1, 2},
    [20] = {1, 1, 2},

    [21] = {1, 3, 1},
    [22] = {1, 3, 1},
    [23] = {1, 3, 1},

    [24] = {1, 3, 2},
    [25] = {1, 3, 2},

    [26] = {1, 4, 2},
    [27] = {1, 4, 2},

    [28] = {1, 4, 4},
    [29] = {1, 4, 4},
    [30] = {1, 4, 4},

    [31] = {1, 5, 2},

    [32] = {1, 5, 1},
    [33] = {1, 5, 1},

    [34] = {1, 5, 4},

    [35] = {1, 6, 2},
    [36] = {1, 6, 2},
    [37] = {1, 6, 2},
    [38] = {1, 6, 2},
    [39] = {1, 6, 2},

    [40] = {1, 7, 2},

    [41] = {2, 1, 3},
    [42] = {2, 1, 3},
    [43] = {2, 1, 3},
    [44] = {2, 1, 3},
    [45] = {2, 1, 3},

    [46] = {2, 2, 1},
    [47] = {2, 2, 1},

    [48] = {2, 2, 3},
    [49] = {2, 2, 3},
    [50] = {2, 2, 3},

    [51] = {2, 3, 3},
    [52] = {2, 3, 3},
    [53] = {2, 3, 3},
    [54] = {2, 3, 3},

    [55] = {1, 3, 2},

    [56] = {2, 4, 2},
    [57] = {2, 4, 2},

    [58] = {2, 4, 3},
    [59] = {2, 4, 3},
    [60] = {2, 4, 3},
})
