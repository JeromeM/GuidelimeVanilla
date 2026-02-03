--[[
Guidelime Vanilla - Talent Templates

Warrior talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Arms
2 = Fury
3 = Protection

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Arms Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/arms-warrior-leveling-guide-1-60
GLV:RegisterTalentTemplate("WARRIOR", "Arms (Icy Veins)", "leveling", {
    -- Level 10-12: Improved Rend (3/3) - Arms
    [10] = {1, 1, 3},  -- Improved Rend 1/3
    [11] = {1, 1, 3},  -- Improved Rend 2/3
    [12] = {1, 1, 3},  -- Improved Rend 3/3

    -- Level 13-14: Deflection (2/5) - Arms
    [13] = {1, 1, 2},  -- Deflection 1/5
    [14] = {1, 1, 2},  -- Deflection 2/5

    -- Level 15-16: Improved Charge (2/2) - Arms
    [15] = {1, 2, 1},  -- Improved Charge 1/2
    [16] = {1, 2, 1},  -- Improved Charge 2/2

    -- Level 17-19: Tactical Mastery (3/5) - Arms
    [17] = {1, 2, 2},  -- Tactical Mastery 1/5
    [18] = {1, 2, 2},  -- Tactical Mastery 2/5
    [19] = {1, 2, 2},  -- Tactical Mastery 3/5

    -- Level 20-21: Improved Overpower (2/2) - Arms
    [20] = {1, 2, 3},  -- Improved Overpower 1/2
    [21] = {1, 2, 3},  -- Improved Overpower 2/2

    -- Level 22-24: Deep Wounds (3/3) - Arms
    [22] = {1, 3, 3},  -- Deep Wounds 1/3
    [23] = {1, 3, 3},  -- Deep Wounds 2/3
    [24] = {1, 3, 3},  -- Deep Wounds 3/3

    -- Level 25-26: Tactical Mastery (5/5) - Arms
    [25] = {1, 2, 2},  -- Tactical Mastery 4/5
    [26] = {1, 2, 2},  -- Tactical Mastery 5/5

    -- Level 27: Anger Management (1/1) - Arms
    [27] = {1, 3, 2},  -- Anger Management 1/1

    -- Level 28-29: Two-Handed Weapon Specialization (2/5) - Arms
    [28] = {1, 4, 1},  -- Two-Handed Weapon Specialization 1/5
    [29] = {1, 4, 1},  -- Two-Handed Weapon Specialization 2/5

    -- Level 30: Sweeping Strikes (1/1) - Arms
    [30] = {1, 5, 2},  -- Sweeping Strikes 1/1

    -- Level 31-35: Axe Specialization (5/5) - Arms
    [31] = {1, 5, 1},  -- Axe Specialization 1/5
    [32] = {1, 5, 1},  -- Axe Specialization 2/5
    [33] = {1, 5, 1},  -- Axe Specialization 3/5
    [34] = {1, 5, 1},  -- Axe Specialization 4/5
    [35] = {1, 5, 1},  -- Axe Specialization 5/5

    -- Level 36-38: Improved Hamstring (3/3) - Arms
    [36] = {1, 6, 1},  -- Improved Hamstring 1/3
    [37] = {1, 6, 1},  -- Improved Hamstring 2/3
    [38] = {1, 6, 1},  -- Improved Hamstring 3/3

    -- Level 39: Two-Handed Weapon Specialization (3/5) - Arms
    [39] = {1, 4, 1},  -- Two-Handed Weapon Specialization 3/5

    -- Level 40: Mortal Strike (1/1) - Arms
    [40] = {1, 7, 2},  -- Mortal Strike 1/1

    -- Level 41-45: Cruelty (5/5) - Fury
    [41] = {2, 1, 2},  -- Cruelty 1/5
    [42] = {2, 1, 2},  -- Cruelty 2/5
    [43] = {2, 1, 2},  -- Cruelty 3/5
    [44] = {2, 1, 2},  -- Cruelty 4/5
    [45] = {2, 1, 2},  -- Cruelty 5/5

    -- Level 46-50: Booming Voice (5/5) - Fury
    [46] = {2, 1, 1},  -- Booming Voice 1/5
    [47] = {2, 1, 1},  -- Booming Voice 2/5
    [48] = {2, 1, 1},  -- Booming Voice 3/5
    [49] = {2, 1, 1},  -- Booming Voice 4/5
    [50] = {2, 1, 1},  -- Booming Voice 5/5

    -- Level 51: Piercing Howl (1/1) - Fury
    [51] = {2, 3, 1},  -- Piercing Howl 1/1

    -- Level 52-54: Blood Craze (3/3) - Fury
    [52] = {2, 2, 4},  -- Blood Craze 1/3
    [53] = {2, 2, 4},  -- Blood Craze 2/3
    [54] = {2, 2, 4},  -- Blood Craze 3/3

    -- Level 55: Improved Battle Shout (1/5) - Fury
    [55] = {2, 1, 3},  -- Improved Battle Shout 1/5

    -- Level 56-60: Enrage (5/5) - Fury
    [56] = {2, 4, 1},  -- Enrage 1/5
    [57] = {2, 4, 1},  -- Enrage 2/5
    [58] = {2, 4, 1},  -- Enrage 3/5
    [59] = {2, 4, 1},  -- Enrage 4/5
    [60] = {2, 4, 1},  -- Enrage 5/5
})

-- Fury Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/fury-warrior-leveling-guide-1-60
GLV:RegisterTalentTemplate("WARRIOR", "Fury (Icy Veins)", "leveling", {
    -- Level 10-14: Cruelty (5/5) - Fury
    [10] = {2, 1, 2},  -- Cruelty 1/5
    [11] = {2, 1, 2},  -- Cruelty 2/5
    [12] = {2, 1, 2},  -- Cruelty 3/5
    [13] = {2, 1, 2},  -- Cruelty 4/5
    [14] = {2, 1, 2},  -- Cruelty 5/5

    -- Level 15-19: Booming Voice (5/5) - Fury
    [15] = {2, 1, 1},  -- Booming Voice 1/5
    [16] = {2, 1, 1},  -- Booming Voice 2/5
    [17] = {2, 1, 1},  -- Booming Voice 3/5
    [18] = {2, 1, 1},  -- Booming Voice 4/5
    [19] = {2, 1, 1},  -- Booming Voice 5/5

    -- Level 20: Piercing Howl (1/1) - Fury
    [20] = {2, 3, 1},  -- Piercing Howl 1/1

    -- Level 21-23: Blood Craze (3/3) - Fury
    [21] = {2, 2, 4},  -- Blood Craze 1/3
    [22] = {2, 2, 4},  -- Blood Craze 2/3
    [23] = {2, 2, 4},  -- Blood Craze 3/3

    -- Level 24: Improved Battle Shout (1/5) - Fury
    [24] = {2, 1, 3},  -- Improved Battle Shout 1/5

    -- Level 25-29: Enrage (5/5) - Fury
    [25] = {2, 4, 1},  -- Enrage 1/5
    [26] = {2, 4, 1},  -- Enrage 2/5
    [27] = {2, 4, 1},  -- Enrage 3/5
    [28] = {2, 4, 1},  -- Enrage 4/5
    [29] = {2, 4, 1},  -- Enrage 5/5

    -- Level 30: Death Wish (1/1) - Fury
    [30] = {2, 5, 2},  -- Death Wish 1/1

    -- Level 31-34: Improved Battle Shout (5/5) - Fury
    [31] = {2, 1, 3},  -- Improved Battle Shout 2/5
    [32] = {2, 1, 3},  -- Improved Battle Shout 3/5
    [33] = {2, 1, 3},  -- Improved Battle Shout 4/5
    [34] = {2, 1, 3},  -- Improved Battle Shout 5/5

    -- Level 35-39: Flurry (5/5) - Fury
    [35] = {2, 5, 3},  -- Flurry 1/5
    [36] = {2, 5, 3},  -- Flurry 2/5
    [37] = {2, 5, 3},  -- Flurry 3/5
    [38] = {2, 5, 3},  -- Flurry 4/5
    [39] = {2, 5, 3},  -- Flurry 5/5

    -- Level 40: Bloodthirst (1/1) - Fury
    [40] = {2, 7, 2},  -- Bloodthirst 1/1

    -- Level 41-42: Deflection (2/5) - Arms
    [41] = {1, 1, 2},  -- Deflection 1/5
    [42] = {1, 1, 2},  -- Deflection 2/5

    -- Level 43-45: Improved Rend (3/3) - Arms
    [43] = {1, 1, 3},  -- Improved Rend 1/3
    [44] = {1, 1, 3},  -- Improved Rend 2/3
    [45] = {1, 1, 3},  -- Improved Rend 3/3

    -- Level 46-50: Tactical Mastery (5/5) - Arms
    [46] = {1, 2, 2},  -- Tactical Mastery 1/5
    [47] = {1, 2, 2},  -- Tactical Mastery 2/5
    [48] = {1, 2, 2},  -- Tactical Mastery 3/5
    [49] = {1, 2, 2},  -- Tactical Mastery 4/5
    [50] = {1, 2, 2},  -- Tactical Mastery 5/5

    -- Level 51-52: Improved Overpower (2/2) - Arms
    [51] = {1, 2, 3},  -- Improved Overpower 1/2
    [52] = {1, 2, 3},  -- Improved Overpower 2/2

    -- Level 53: Anger Management (1/1) - Arms
    [53] = {1, 3, 2},  -- Anger Management 1/1

    -- Level 54-56: Deep Wounds (3/3) - Arms
    [54] = {1, 3, 3},  -- Deep Wounds 1/3
    [55] = {1, 3, 3},  -- Deep Wounds 2/3
    [56] = {1, 3, 3},  -- Deep Wounds 3/3

    -- Level 57-60: Two-Handed Weapon Specialization (4/5) - Arms
    [57] = {1, 4, 1},  -- Two-Handed Weapon Specialization 1/5
    [58] = {1, 4, 1},  -- Two-Handed Weapon Specialization 2/5
    [59] = {1, 4, 1},  -- Two-Handed Weapon Specialization 3/5
    [60] = {1, 4, 1},  -- Two-Handed Weapon Specialization 4/5
})
