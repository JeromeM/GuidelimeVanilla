--[[
Guidelime Vanilla - Talent Templates

Hunter talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Beast Mastery
2 = Marksmanship
3 = Survival

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Beast Mastery Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/beast-mastery-hunter-leveling-guide-1-60
GLV:RegisterTalentTemplate("HUNTER", "Beast Mastery (Icy Veins)", "leveling", {
    -- Level 10-14: Improved Aspect of the Hawk (5/5) - Beast Mastery
    [10] = {1, 1, 2},  -- Improved Aspect of the Hawk 1/5
    [11] = {1, 1, 2},  -- Improved Aspect of the Hawk 2/5
    [12] = {1, 1, 2},  -- Improved Aspect of the Hawk 3/5
    [13] = {1, 1, 2},  -- Improved Aspect of the Hawk 4/5
    [14] = {1, 1, 2},  -- Improved Aspect of the Hawk 5/5

    -- Level 15-16: Improved Revive Pet (2/2) - Beast Mastery
    [15] = {1, 2, 4},  -- Improved Revive Pet 1/2
    [16] = {1, 2, 4},  -- Improved Revive Pet 2/2

    -- Level 17-19: Thick Hide (3/3) - Beast Mastery
    [17] = {1, 2, 1},  -- Thick Hide 1/3
    [18] = {1, 2, 1},  -- Thick Hide 2/3
    [19] = {1, 2, 1},  -- Thick Hide 3/3

    -- Level 20-21: Pathfinding (2/2) - Beast Mastery
    [20] = {1, 3, 4},  -- Pathfinding 1/2
    [21] = {1, 3, 4},  -- Pathfinding 2/2

    -- Level 22: Bestial Swiftness (1/1) - Beast Mastery
    [22] = {1, 3, 1},  -- Bestial Swiftness 1/1

    -- Level 23-27: Unleashed Fury (5/5) - Beast Mastery
    [23] = {1, 3, 2},  -- Unleashed Fury 1/5
    [24] = {1, 3, 2},  -- Unleashed Fury 2/5
    [25] = {1, 3, 2},  -- Unleashed Fury 3/5
    [26] = {1, 3, 2},  -- Unleashed Fury 4/5
    [27] = {1, 3, 2},  -- Unleashed Fury 5/5

    -- Level 28-29: Ferocity (2/5) - Beast Mastery
    [28] = {1, 4, 3},  -- Ferocity 1/5
    [29] = {1, 4, 3},  -- Ferocity 2/5

    -- Level 30: Intimidation (1/1) - Beast Mastery
    [30] = {1, 5, 2},  -- Intimidation 1/1

    -- Level 31-33: Ferocity (5/5) - Beast Mastery
    [31] = {1, 4, 3},  -- Ferocity 3/5
    [32] = {1, 4, 3},  -- Ferocity 4/5
    [33] = {1, 4, 3},  -- Ferocity 5/5

    -- Level 34: Bestial Discipline (1/2) - Beast Mastery
    [34] = {1, 5, 4},  -- Bestial Discipline 1/2

    -- Level 35-39: Frenzy (5/5) - Beast Mastery
    [35] = {1, 6, 2},  -- Frenzy 1/5
    [36] = {1, 6, 2},  -- Frenzy 2/5
    [37] = {1, 6, 2},  -- Frenzy 3/5
    [38] = {1, 6, 2},  -- Frenzy 4/5
    [39] = {1, 6, 2},  -- Frenzy 5/5

    -- Level 40: Bestial Wrath (1/1) - Beast Mastery
    [40] = {1, 7, 2},  -- Bestial Wrath 1/1

    -- Level 41-45: Improved Concussive Shot (5/5) - Marksmanship
    [41] = {2, 1, 1},  -- Improved Concussive Shot 1/5
    [42] = {2, 1, 1},  -- Improved Concussive Shot 2/5
    [43] = {2, 1, 1},  -- Improved Concussive Shot 3/5
    [44] = {2, 1, 1},  -- Improved Concussive Shot 4/5
    [45] = {2, 1, 1},  -- Improved Concussive Shot 5/5

    -- Level 46-50: Lethal Shots (5/5) - Marksmanship
    [46] = {2, 1, 3},  -- Lethal Shots 1/5
    [47] = {2, 1, 3},  -- Lethal Shots 2/5
    [48] = {2, 1, 3},  -- Lethal Shots 3/5
    [49] = {2, 1, 3},  -- Lethal Shots 4/5
    [50] = {2, 1, 3},  -- Lethal Shots 5/5

    -- Level 51: Aimed Shot (1/1) - Marksmanship
    [51] = {2, 3, 3},  -- Aimed Shot 1/1

    -- Level 52-54: Hawk Eye (3/3) - Marksmanship
    [52] = {2, 2, 2},  -- Hawk Eye 1/3
    [53] = {2, 2, 2},  -- Hawk Eye 2/3
    [54] = {2, 2, 2},  -- Hawk Eye 3/3

    -- Level 55: Efficiency (1/5) - Marksmanship
    [55] = {2, 1, 2},  -- Efficiency 1/5

    -- Level 56-60: Mortal Shots (5/5) - Marksmanship
    [56] = {2, 3, 1},  -- Mortal Shots 1/5
    [57] = {2, 3, 1},  -- Mortal Shots 2/5
    [58] = {2, 3, 1},  -- Mortal Shots 3/5
    [59] = {2, 3, 1},  -- Mortal Shots 4/5
    [60] = {2, 3, 1},  -- Mortal Shots 5/5
})
