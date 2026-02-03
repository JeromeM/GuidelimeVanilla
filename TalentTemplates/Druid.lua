--[[
Guidelime Vanilla - Talent Templates

Druid talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Balance
2 = Feral Combat
3 = Restoration

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Feral Combat Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/feral-druid-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("DRUID", "Feral (Icy Veins)", "leveling", {
    -- Level 10-14: Ferocity (5/5) - Feral
    [10] = {2, 1, 1},  -- Ferocity 1/5
    [11] = {2, 1, 1},  -- Ferocity 2/5
    [12] = {2, 1, 1},  -- Ferocity 3/5
    [13] = {2, 1, 1},  -- Ferocity 4/5
    [14] = {2, 1, 1},  -- Ferocity 5/5

    -- Level 15-19: Feral Aggression (5/5) - Feral
    [15] = {2, 1, 2},  -- Feral Aggression 1/5
    [16] = {2, 1, 2},  -- Feral Aggression 2/5
    [17] = {2, 1, 2},  -- Feral Aggression 3/5
    [18] = {2, 1, 2},  -- Feral Aggression 4/5
    [19] = {2, 1, 2},  -- Feral Aggression 5/5

    -- Level 20-21: Feline Swiftness (2/2) - Feral
    [20] = {2, 3, 1},  -- Feline Swiftness 1/2
    [21] = {2, 3, 1},  -- Feline Swiftness 2/2

    -- Level 22-26: Furor (5/5) - Restoration
    [22] = {3, 1, 1},  -- Furor 1/5
    [23] = {3, 1, 1},  -- Furor 2/5
    [24] = {3, 1, 1},  -- Furor 3/5
    [25] = {3, 1, 1},  -- Furor 4/5
    [26] = {3, 1, 1},  -- Furor 5/5

    -- Level 27: Feral Charge (1/1) - Feral
    [27] = {2, 4, 2},  -- Feral Charge 1/1

    -- Level 28-30: Sharpened Claws (3/3) - Feral
    [28] = {2, 2, 1},  -- Sharpened Claws 1/3
    [29] = {2, 2, 1},  -- Sharpened Claws 2/3
    [30] = {2, 2, 1},  -- Sharpened Claws 3/3

    -- Level 31-32: Blood Frenzy (2/2) - Feral
    [31] = {2, 4, 1},  -- Blood Frenzy 1/2
    [32] = {2, 4, 1},  -- Blood Frenzy 2/2

    -- Level 33-35: Predatory Strikes (3/3) - Feral
    [33] = {2, 3, 3},  -- Predatory Strikes 1/3
    [34] = {2, 3, 3},  -- Predatory Strikes 2/3
    [35] = {2, 3, 3},  -- Predatory Strikes 3/3

    -- Level 36: Faerie Fire (Feral) (1/1) - Feral
    [36] = {2, 4, 4},  -- Faerie Fire (Feral) 1/1

    -- Level 37-38: Savage Fury (2/2) - Feral
    [37] = {2, 5, 1},  -- Savage Fury 1/2
    [38] = {2, 5, 1},  -- Savage Fury 2/2

    -- Level 39: Improved Shred (1/2) - Feral
    [39] = {2, 5, 3},  -- Improved Shred 1/2

    -- Level 40-44: Heart of the Wild (5/5) - Feral
    [40] = {2, 6, 2},  -- Heart of the Wild 1/5
    [41] = {2, 6, 2},  -- Heart of the Wild 2/5
    [42] = {2, 6, 2},  -- Heart of the Wild 3/5
    [43] = {2, 6, 2},  -- Heart of the Wild 4/5
    [44] = {2, 6, 2},  -- Heart of the Wild 5/5

    -- Level 45: Leader of the Pack (1/1) - Feral
    [45] = {2, 7, 2},  -- Leader of the Pack 1/1

    -- Level 46: Nature's Grasp (1/1) - Balance
    [46] = {1, 1, 1},  -- Nature's Grasp 1/1

    -- Level 47-50: Improved Nature's Grasp (4/4) - Balance
    [47] = {1, 1, 2},  -- Improved Nature's Grasp 1/4
    [48] = {1, 1, 2},  -- Improved Nature's Grasp 2/4
    [49] = {1, 1, 2},  -- Improved Nature's Grasp 3/4
    [50] = {1, 1, 2},  -- Improved Nature's Grasp 4/4

    -- Level 51-55: Natural Weapons (5/5) - Balance
    [51] = {1, 2, 3},  -- Natural Weapons 1/5
    [52] = {1, 2, 3},  -- Natural Weapons 2/5
    [53] = {1, 2, 3},  -- Natural Weapons 3/5
    [54] = {1, 2, 3},  -- Natural Weapons 4/5
    [55] = {1, 2, 3},  -- Natural Weapons 5/5

    -- Level 56: Omen of Clarity (1/1) - Balance
    [56] = {1, 3, 1},  -- Omen of Clarity 1/1

    -- Level 57: Improved Shred (2/2) - Feral
    [57] = {2, 5, 3},  -- Improved Shred 2/2

    -- Level 58-60: Natural Shapeshifter (3/3) - Restoration
    [58] = {3, 1, 3},  -- Natural Shapeshifter 1/3
    [59] = {3, 1, 3},  -- Natural Shapeshifter 2/3
    [60] = {3, 1, 3},  -- Natural Shapeshifter 3/3
})

-- Balance (Moonkin) Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/balance-druid-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("DRUID", "Balance (Icy Veins)", "leveling", {
    -- Level 10: Nature's Grasp (1/1) - Balance
    [10] = {1, 1, 1},  -- Nature's Grasp 1/1

    -- Level 11-15: Improved Wrath (5/5) - Balance
    [11] = {1, 1, 3},  -- Improved Wrath 1/5
    [12] = {1, 1, 3},  -- Improved Wrath 2/5
    [13] = {1, 1, 3},  -- Improved Wrath 3/5
    [14] = {1, 1, 3},  -- Improved Wrath 4/5
    [15] = {1, 1, 3},  -- Improved Wrath 5/5

    -- Level 16-20: Improved Moonfire (5/5) - Balance
    [16] = {1, 2, 1},  -- Improved Moonfire 1/5
    [17] = {1, 2, 1},  -- Improved Moonfire 2/5
    [18] = {1, 2, 1},  -- Improved Moonfire 3/5
    [19] = {1, 2, 1},  -- Improved Moonfire 4/5
    [20] = {1, 2, 1},  -- Improved Moonfire 5/5

    -- Level 21-22: Nature's Reach (2/2) - Balance
    [21] = {1, 3, 3},  -- Nature's Reach 1/2
    [22] = {1, 3, 3},  -- Nature's Reach 2/2

    -- Level 23-25: Improved Entangling Roots (3/3) - Balance
    [23] = {1, 2, 4},  -- Improved Entangling Roots 1/3
    [24] = {1, 2, 4},  -- Improved Entangling Roots 2/3
    [25] = {1, 2, 4},  -- Improved Entangling Roots 3/3

    -- Level 26-30: Vengeance (5/5) - Balance
    [26] = {1, 4, 2},  -- Vengeance 1/5
    [27] = {1, 4, 2},  -- Vengeance 2/5
    [28] = {1, 4, 2},  -- Vengeance 3/5
    [29] = {1, 4, 2},  -- Vengeance 4/5
    [30] = {1, 4, 2},  -- Vengeance 5/5

    -- Level 31: Nature's Grace (1/1) - Balance
    [31] = {1, 5, 2},  -- Nature's Grace 1/1

    -- Level 32-34: Moonglow (3/3) - Balance
    [32] = {1, 4, 3},  -- Moonglow 1/3
    [33] = {1, 4, 3},  -- Moonglow 2/3
    [34] = {1, 4, 3},  -- Moonglow 3/3

    -- Level 35-39: Moonfury (5/5) - Balance
    [35] = {1, 6, 2},  -- Moonfury 1/5
    [36] = {1, 6, 2},  -- Moonfury 2/5
    [37] = {1, 6, 2},  -- Moonfury 3/5
    [38] = {1, 6, 2},  -- Moonfury 4/5
    [39] = {1, 6, 2},  -- Moonfury 5/5

    -- Level 40: Moonkin Form (1/1) - Balance
    [40] = {1, 7, 2},  -- Moonkin Form 1/1

    -- Level 41-45: Improved Starfire (5/5) - Balance
    [41] = {1, 5, 3},  -- Improved Starfire 1/5
    [42] = {1, 5, 3},  -- Improved Starfire 2/5
    [43] = {1, 5, 3},  -- Improved Starfire 3/5
    [44] = {1, 5, 3},  -- Improved Starfire 4/5
    [45] = {1, 5, 3},  -- Improved Starfire 5/5

    -- Level 46-50: Improved Mark of the Wild (5/5) - Restoration
    [46] = {3, 1, 2},  -- Improved Mark of the Wild 1/5
    [47] = {3, 1, 2},  -- Improved Mark of the Wild 2/5
    [48] = {3, 1, 2},  -- Improved Mark of the Wild 3/5
    [49] = {3, 1, 2},  -- Improved Mark of the Wild 4/5
    [50] = {3, 1, 2},  -- Improved Mark of the Wild 5/5

    -- Level 51-55: Improved Healing Touch (5/5) - Restoration
    [51] = {3, 2, 1},  -- Improved Healing Touch 1/5
    [52] = {3, 2, 1},  -- Improved Healing Touch 2/5
    [53] = {3, 2, 1},  -- Improved Healing Touch 3/5
    [54] = {3, 2, 1},  -- Improved Healing Touch 4/5
    [55] = {3, 2, 1},  -- Improved Healing Touch 5/5

    -- Level 56: Insect Swarm (1/1) - Balance
    [56] = {1, 4, 1},  -- Insect Swarm 1/1

    -- Level 57-59: Reflection (3/3) - Restoration
    [57] = {3, 3, 2},  -- Reflection 1/3
    [58] = {3, 3, 2},  -- Reflection 2/3
    [59] = {3, 3, 2},  -- Reflection 3/3

    -- Level 60: Nature's Focus (1/5) - Restoration
    [60] = {3, 2, 2},  -- Nature's Focus 1/5
})
