--[[
Guidelime Vanilla - Talent Templates

Shaman talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Elemental
2 = Enhancement
3 = Restoration

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Enhancement Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/enhancement-shaman-leveling-guide-1-60
GLV:RegisterTalentTemplate("SHAMAN", "Enhancement (Icy Veins)", "leveling", {
    -- Level 10-14: Shield Specialization (5/5) - Enhancement
    [10] = {2, 1, 2},  -- Shield Specialization 1/5
    [11] = {2, 1, 2},  -- Shield Specialization 2/5
    [12] = {2, 1, 2},  -- Shield Specialization 3/5
    [13] = {2, 1, 2},  -- Shield Specialization 4/5
    [14] = {2, 1, 2},  -- Shield Specialization 5/5

    -- Level 15-19: Thundering Strikes (5/5) - Enhancement
    [15] = {2, 2, 3},  -- Thundering Strikes 1/5
    [16] = {2, 2, 3},  -- Thundering Strikes 2/5
    [17] = {2, 2, 3},  -- Thundering Strikes 3/5
    [18] = {2, 2, 3},  -- Thundering Strikes 4/5
    [19] = {2, 2, 3},  -- Thundering Strikes 5/5

    -- Level 20: Two-Handed Axes and Maces (1/1) - Enhancement
    [20] = {2, 4, 3},  -- Two-Handed Axes and Maces 1/1

    -- Level 21-23: Improved Lightning Shield (3/3) - Restoration
    [21] = {3, 1, 2},  -- Improved Lightning Shield 1/3
    [22] = {3, 1, 2},  -- Improved Lightning Shield 2/3
    [23] = {3, 1, 2},  -- Improved Lightning Shield 3/3

    -- Level 24: Anticipation (1/5) - Enhancement
    [24] = {2, 1, 1},  -- Anticipation 1/5

    -- Level 25-29: Flurry (5/5) - Enhancement
    [25] = {2, 3, 3},  -- Flurry 1/5
    [26] = {2, 3, 3},  -- Flurry 2/5
    [27] = {2, 3, 3},  -- Flurry 3/5
    [28] = {2, 3, 3},  -- Flurry 4/5
    [29] = {2, 3, 3},  -- Flurry 5/5

    -- Level 30: Parry (1/1) - Enhancement
    [30] = {2, 5, 3},  -- Parry 1/1

    -- Level 31-33: Elemental Weapons (3/3) - Enhancement
    [31] = {2, 4, 1},  -- Elemental Weapons 1/3
    [32] = {2, 4, 1},  -- Elemental Weapons 2/3
    [33] = {2, 4, 1},  -- Elemental Weapons 3/3

    -- Level 34: Anticipation (2/5) - Enhancement
    [34] = {2, 1, 1},  -- Anticipation 2/5

    -- Level 35-39: Weapon Mastery (5/5) - Enhancement
    [35] = {2, 5, 1},  -- Weapon Mastery 1/5
    [36] = {2, 5, 1},  -- Weapon Mastery 2/5
    [37] = {2, 5, 1},  -- Weapon Mastery 3/5
    [38] = {2, 5, 1},  -- Weapon Mastery 4/5
    [39] = {2, 5, 1},  -- Weapon Mastery 5/5

    -- Level 40: Stormstrike (1/1) - Enhancement
    [40] = {2, 7, 2},  -- Stormstrike 1/1

    -- Level 41-45: Improved Healing Wave (5/5) - Restoration
    [41] = {3, 1, 3},  -- Improved Healing Wave 1/5
    [42] = {3, 1, 3},  -- Improved Healing Wave 2/5
    [43] = {3, 1, 3},  -- Improved Healing Wave 3/5
    [44] = {3, 1, 3},  -- Improved Healing Wave 4/5
    [45] = {3, 1, 3},  -- Improved Healing Wave 5/5

    -- Level 46-47: Improved Reincarnation (2/2) - Restoration
    [46] = {3, 2, 3},  -- Improved Reincarnation 1/2
    [47] = {3, 2, 3},  -- Improved Reincarnation 2/2

    -- Level 48-50: Totemic Focus (3/5) - Restoration
    [48] = {3, 2, 2},  -- Totemic Focus 1/5
    [49] = {3, 2, 2},  -- Totemic Focus 2/5
    [50] = {3, 2, 2},  -- Totemic Focus 3/5

    -- Level 51-53: Nature's Guidance (3/3) - Restoration
    [51] = {3, 3, 1},  -- Nature's Guidance 1/3
    [52] = {3, 3, 1},  -- Nature's Guidance 2/3
    [53] = {3, 3, 1},  -- Nature's Guidance 3/3

    -- Level 54-55: Enhancing Totems (2/2) - Enhancement
    [54] = {2, 3, 2},  -- Enhancing Totems 1/2
    [55] = {2, 3, 2},  -- Enhancing Totems 2/2

    -- Level 56-58: Anticipation (5/5) - Enhancement
    [56] = {2, 1, 1},  -- Anticipation 3/5
    [57] = {2, 1, 1},  -- Anticipation 4/5
    [58] = {2, 1, 1},  -- Anticipation 5/5

    -- Level 59-60: Improved Weapon Totems (2/2) - Enhancement
    [59] = {2, 5, 2},  -- Improved Weapon Totems 1/2
    [60] = {2, 5, 2},  -- Improved Weapon Totems 2/2
})

-- Elemental Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/elemental-shaman-leveling-guide-1-60
GLV:RegisterTalentTemplate("SHAMAN", "Elemental (Icy Veins)", "leveling", {
    -- Level 10-14: Convection (5/5) - Elemental
    [10] = {1, 1, 2},  -- Convection 1/5
    [11] = {1, 1, 2},  -- Convection 2/5
    [12] = {1, 1, 2},  -- Convection 3/5
    [13] = {1, 1, 2},  -- Convection 4/5
    [14] = {1, 1, 2},  -- Convection 5/5

    -- Level 15-17: Call of Flame (3/3) - Elemental
    [15] = {1, 2, 1},  -- Call of Flame 1/3
    [16] = {1, 2, 1},  -- Call of Flame 2/3
    [17] = {1, 2, 1},  -- Call of Flame 3/3

    -- Level 18-19: Concussion (2/5) - Elemental
    [18] = {1, 1, 3},  -- Concussion 1/5
    [19] = {1, 1, 3},  -- Concussion 2/5

    -- Level 20: Elemental Focus (1/1) - Elemental
    [20] = {1, 3, 1},  -- Elemental Focus 1/1

    -- Level 21-25: Call of Thunder (5/5) - Elemental
    [21] = {1, 3, 2},  -- Call of Thunder 1/5
    [22] = {1, 3, 2},  -- Call of Thunder 2/5
    [23] = {1, 3, 2},  -- Call of Thunder 3/5
    [24] = {1, 3, 2},  -- Call of Thunder 4/5
    [25] = {1, 3, 2},  -- Call of Thunder 5/5

    -- Level 26-28: Eye of the Storm (3/3) - Elemental
    [26] = {1, 4, 1},  -- Eye of the Storm 1/3
    [27] = {1, 4, 1},  -- Eye of the Storm 2/3
    [28] = {1, 4, 1},  -- Eye of the Storm 3/3

    -- Level 29: Concussion (3/5) - Elemental
    [29] = {1, 1, 3},  -- Concussion 3/5

    -- Level 30: Elemental Fury (1/1) - Elemental
    [30] = {1, 5, 2},  -- Elemental Fury 1/1

    -- Level 31-32: Storm Reach (2/2) - Elemental
    [31] = {1, 4, 3},  -- Storm Reach 1/2
    [32] = {1, 4, 3},  -- Storm Reach 2/2

    -- Level 33-34: Concussion (5/5) - Elemental
    [33] = {1, 1, 3},  -- Concussion 4/5
    [34] = {1, 1, 3},  -- Concussion 5/5

    -- Level 35-39: Lightning Mastery (5/5) - Elemental
    [35] = {1, 6, 3},  -- Lightning Mastery 1/5
    [36] = {1, 6, 3},  -- Lightning Mastery 2/5
    [37] = {1, 6, 3},  -- Lightning Mastery 3/5
    [38] = {1, 6, 3},  -- Lightning Mastery 4/5
    [39] = {1, 6, 3},  -- Lightning Mastery 5/5

    -- Level 40: Elemental Mastery (1/1) - Elemental
    [40] = {1, 7, 2},  -- Elemental Mastery 1/1

    -- Level 41-45: Improved Healing Wave (5/5) - Restoration
    [41] = {3, 1, 3},  -- Improved Healing Wave 1/5
    [42] = {3, 1, 3},  -- Improved Healing Wave 2/5
    [43] = {3, 1, 3},  -- Improved Healing Wave 3/5
    [44] = {3, 1, 3},  -- Improved Healing Wave 4/5
    [45] = {3, 1, 3},  -- Improved Healing Wave 5/5

    -- Level 46-47: Improved Reincarnation (2/2) - Restoration
    [46] = {3, 2, 3},  -- Improved Reincarnation 1/2
    [47] = {3, 2, 3},  -- Improved Reincarnation 2/2

    -- Level 48-50: Totemic Focus (3/5) - Restoration
    [48] = {3, 2, 2},  -- Totemic Focus 1/5
    [49] = {3, 2, 2},  -- Totemic Focus 2/5
    [50] = {3, 2, 2},  -- Totemic Focus 3/5

    -- Level 51-53: Nature's Guidance (3/3) - Restoration
    [51] = {3, 3, 1},  -- Nature's Guidance 1/3
    [52] = {3, 3, 1},  -- Nature's Guidance 2/3
    [53] = {3, 3, 1},  -- Nature's Guidance 3/3

    -- Level 54: Totemic Mastery (1/1) - Restoration
    [54] = {3, 4, 2},  -- Totemic Mastery 1/1

    -- Level 55: Totemic Focus (4/5) - Restoration
    [55] = {3, 2, 2},  -- Totemic Focus 4/5

    -- Level 56-60: Tidal Mastery (5/5) - Restoration
    [56] = {3, 4, 3},  -- Tidal Mastery 1/5
    [57] = {3, 4, 3},  -- Tidal Mastery 2/5
    [58] = {3, 4, 3},  -- Tidal Mastery 3/5
    [59] = {3, 4, 3},  -- Tidal Mastery 4/5
    [60] = {3, 4, 3},  -- Tidal Mastery 5/5
})
