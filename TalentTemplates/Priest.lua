--[[
Guidelime Vanilla - Talent Templates

Priest talent templates for leveling

Tree Index:
1 = Discipline
2 = Holy
3 = Shadow

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Discipline Leveling Build (TurtleWoW)
-- Source: https://talents.turtlecraft.gg/priest?points=RoACRDaAZAAoB-CoFCAB-F
GLV:RegisterTalentTemplate("PRIEST", "Discipline", "leveling", {
    [10] = {3, 1, 2},   -- Spirit Tap 1/5
    [11] = {3, 1, 2},   -- Spirit Tap 2/5
    [12] = {3, 1, 2},   -- Spirit Tap 3/5
    [13] = {3, 1, 2},   -- Spirit Tap 4/5
    [14] = {3, 1, 2},   -- Spirit Tap 5/5

    [15] = {1, 1, 1},   -- Wand Specialization 1/2
    [16] = {1, 1, 1},   -- Wand Specialization 2/2

    [17] = {1, 1, 3},   -- Mental Agility 1/5
    [18] = {1, 1, 3},   -- Mental Agility 2/5
    [19] = {1, 1, 3},   -- Mental Agility 3/5
    [20] = {1, 1, 3},   -- Mental Agility 4/5
    [21] = {1, 1, 3},   -- Mental Agility 5/5

    [22] = {1, 1, 2},   -- Piercing Light 1/3

    [23] = {1, 2, 4},   -- Improved Power Word: Fortitude 1/2
    [24] = {1, 2, 4},   -- Improved Power Word: Fortitude 2/2

    [25] = {1, 3, 2},   -- Inner Focus 1/1

    [26] = {1, 3, 1},   -- Improved Inner Fire 1/2
    [27] = {1, 3, 1},   -- Improved Inner Fire 2/2
    
    [28] = {1, 3, 4},   -- Meditation 1/3
    [29] = {1, 3, 4},   -- Meditation 2/3
    [30] = {1, 3, 4},   -- Meditation 3/3

    [31] = {1, 4, 2},   -- Purifying Flames 1/2
    [32] = {1, 4, 2},   -- Purifying Flames 2/2

    [33] = {1, 4, 1},   -- Searing Light 1/3
    [34] = {1, 4, 1},   -- Searing Light 2/3
    [35] = {1, 4, 1},   -- Searing Light 3/3

    [36] = {1, 5, 2},   -- Enlightenment 1/1

    [37] = {1, 5, 1},   -- Mental Strength 1/3
    [38] = {1, 5, 1},   -- Mental Strength 2/3
    [39] = {1, 5, 1},   -- Mental Strength 3/3

    [40] = {1, 6, 3},   -- Force of Will 1/5
    [41] = {1, 6, 3},   -- Force of Will 2/5
    [42] = {1, 6, 3},   -- Force of Will 3/5
    [43] = {1, 6, 3},   -- Force of Will 4/5
    [44] = {1, 6, 3},   -- Force of Will 5/5

    [45] = {1, 7, 2},   -- Chastise 1/1

    [46] = {2, 1, 2},   -- Holy Focus 1/2
    [47] = {2, 1, 2},   -- Holy Focus 2/2

    [48] = {2, 1, 3},   -- Divinity 1/5
    [49] = {2, 1, 3},   -- Divinity 2/5
    [50] = {2, 1, 3},   -- Divinity 3/5
    
    [51] = {2, 2, 2},   -- Divine Fury 1/5
    [52] = {2, 2, 2},   -- Divine Fury 2/5
    [53] = {2, 2, 2},   -- Divine Fury 3/5
    [54] = {2, 2, 2},   -- Divine Fury 4/5
    [55] = {2, 2, 2},   -- Divine Fury 5/5

    [56] = {2, 3, 4},   -- Holy Nova 1/1

    [57] = {2, 2, 4},   -- Holy Reach 1/2
    [58] = {2, 2, 4},   -- Holy Reach 2/2

    [59] = {2, 1, 3},   -- Divinity 4/5
    [60] = {2, 1, 3},   -- Divinity 5/5
})
