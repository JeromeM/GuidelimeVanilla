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
-- Guide from TurtleWow Discord by Virasan
-- https://discord.com/channels/466622455805378571/810850799823355915/1364931945624240191
-- https://talents.turtlecraft.gg/warrior?points=FQQCKYDQpAQAB-AoAooAAo-
GLV:RegisterTalentTemplate("WARRIOR", "Arms", "leveling", {
    [10] = {2, 1, 3},   -- Cruelty 1/5
    [11] = {2, 1, 3},   -- Cruelty 2/5
    [12] = {2, 1, 3},   -- Cruelty 3/5
    [13] = {2, 1, 3},   -- Cruelty 4/5
    [14] = {2, 1, 3},   -- Cruelty 5/5

    [15] = {1, 1, 3},   -- Improved Rend 1/2
    [16] = {1, 1, 3},   -- Improved Rend 1/2

    [17] = {1, 1, 2},   -- Tactical Mastery 1/5
    [18] = {1, 1, 2},   -- Tactical Mastery 2/5
    [19] = {1, 1, 2},   -- Tactical Mastery 3/5

    [20] = {1, 2, 4},   -- Improved Thunderclap 1/3

    [21] = {1, 2, 1},   -- Improved Charge 1/2
    [22] = {1, 2, 1},   -- Improved Charge 2/2

    [23] = {1, 1, 2},   -- Tactical Mastery 4/5
    [24] = {1, 1, 2},   -- Tactical Mastery 5/5

    [25] = {1, 3, 2},   -- Improved Overpower 1/2
    [26] = {1, 3, 2},   -- Improved Overpower 2/2

    [27] = {1, 3, 3},   -- Deep Wounds 1/3
    [28] = {1, 3, 3},   -- Deep Wounds 2/3
    [29] = {1, 3, 3},   -- Deep Wounds 3/3

    [30] = {1, 4, 2},   -- Two-handed Weapon Specialization 1/3
    [31] = {1, 4, 2},   -- Two-handed Weapon Specialization 2/3
    [32] = {1, 4, 2},   -- Two-handed Weapon Specialization 3/3

    [33] = {1, 4, 3},   -- Impale 1/2
    [34] = {1, 4, 3},   -- Impale 2/2

    [35] = {1, 5, 2},   -- Sweeping Strikes 1/1

    [36] = {1, 3, 1},   -- Master Strike 1/1

    [37] = {1, 5, 1},   -- Master of Arms 1/5
    [38] = {1, 5, 1},   -- Master of Arms 2/5
    [39] = {1, 5, 1},   -- Master of Arms 3/5
    [40] = {1, 5, 1},   -- Master of Arms 4/5
    [41] = {1, 5, 1},   -- Master of Arms 5/5

    [42] = {1, 6, 1},   -- Improved Slam 1/2
    [43] = {1, 6, 1},   -- Improved Slam 2/2

    [44] = {1, 2, 4},   -- Improved Thunderclap 2/3

    [45] = {1, 7, 2},   -- Mortal Strike 1/1

    [46] = {2, 2, 3},   -- Unbridled Wrath 1/5
    [47] = {2, 2, 3},   -- Unbridled Wrath 2/5
    [48] = {2, 2, 3},   -- Unbridled Wrath 3/5
    [49] = {2, 2, 3},   -- Unbridled Wrath 4/5
    [50] = {2, 2, 3},   -- Unbridled Wrath 5/5

    [51] = {2, 3, 1},   -- Improved Shouts 1/5
    [52] = {2, 3, 1},   -- Improved Shouts 2/5
    [53] = {2, 3, 1},   -- Improved Shouts 3/5
    [54] = {2, 3, 1},   -- Improved Shouts 4/5
    [55] = {2, 3, 1},   -- Improved Shouts 5/5

    [56] = {2, 4, 3},   -- Enrage 1/5
    [57] = {2, 4, 3},   -- Enrage 2/5
    [58] = {2, 4, 3},   -- Enrage 3/5
    [59] = {2, 4, 3},   -- Enrage 4/5
    [60] = {2, 4, 3},   -- Enrage 5/5

})

