--[[
Guidelime Vanilla - Talent Templates

Mage talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Arcane
2 = Fire
3 = Frost

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Single-Target Frost Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/single-target-frost-mage-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("MAGE", "Frost Single-Target (Icy Veins)", "leveling", {
    -- Level 10-12: Elemental Precision (3/3) - Arcane
    [10] = {1, 4, 1},  -- Elemental Precision 1/3
    [11] = {1, 4, 1},  -- Elemental Precision 2/3
    [12] = {1, 4, 1},  -- Elemental Precision 3/3

    -- Level 13-14: Improved Frostbolt (2/5) - Frost
    [13] = {3, 1, 2},  -- Improved Frostbolt 1/5
    [14] = {3, 1, 2},  -- Improved Frostbolt 2/5

    -- Level 15-17: Frostbite (3/3) - Frost
    [15] = {3, 2, 1},  -- Frostbite 1/3
    [16] = {3, 2, 1},  -- Frostbite 2/3
    [17] = {3, 2, 1},  -- Frostbite 3/3

    -- Level 18-22: Ice Shards (5/5) - Frost
    [18] = {3, 1, 3},  -- Ice Shards 1/5
    [19] = {3, 1, 3},  -- Ice Shards 2/5
    [20] = {3, 1, 3},  -- Ice Shards 3/5
    [21] = {3, 1, 3},  -- Ice Shards 4/5
    [22] = {3, 1, 3},  -- Ice Shards 5/5

    -- Level 23-24: Improved Frost Nova (2/2) - Frost
    [23] = {3, 2, 4},  -- Improved Frost Nova 1/2
    [24] = {3, 2, 4},  -- Improved Frost Nova 2/2

    -- Level 25-29: Shatter (5/5) - Frost
    [25] = {3, 3, 3},  -- Shatter 1/5
    [26] = {3, 3, 3},  -- Shatter 2/5
    [27] = {3, 3, 3},  -- Shatter 3/5
    [28] = {3, 3, 3},  -- Shatter 4/5
    [29] = {3, 3, 3},  -- Shatter 5/5

    -- Level 30: Ice Block (1/1) - Frost
    [30] = {3, 5, 2},  -- Ice Block 1/1

    -- Level 31: Cold Snap (1/1) - Frost
    [31] = {3, 3, 1},  -- Cold Snap 1/1

    -- Level 32-34: Improved Frostbolt (5/5) - Frost
    [32] = {3, 1, 2},  -- Improved Frostbolt 3/5
    [33] = {3, 1, 2},  -- Improved Frostbolt 4/5
    [34] = {3, 1, 2},  -- Improved Frostbolt 5/5

    -- Level 35-37: Frost Channeling (3/3) - Frost
    [35] = {3, 4, 3},  -- Frost Channeling 1/3
    [36] = {3, 4, 3},  -- Frost Channeling 2/3
    [37] = {3, 4, 3},  -- Frost Channeling 3/3

    -- Level 38-39: Piercing Ice (2/3) - Frost
    [38] = {3, 2, 3},  -- Piercing Ice 1/3
    [39] = {3, 2, 3},  -- Piercing Ice 2/3

    -- Level 40: Ice Barrier (1/1) - Frost
    [40] = {3, 7, 2},  -- Ice Barrier 1/1

    -- Level 41: Piercing Ice (3/3) - Frost
    [41] = {3, 2, 3},  -- Piercing Ice 3/3

    -- Level 42-43: Arctic Reach (2/2) - Frost
    [42] = {3, 4, 1},  -- Arctic Reach 1/2
    [43] = {3, 4, 1},  -- Arctic Reach 2/2

    -- Level 44-45: Arcane Subtlety (2/2) - Arcane
    [44] = {1, 1, 1},  -- Arcane Subtlety 1/2
    [45] = {1, 1, 1},  -- Arcane Subtlety 2/2

    -- Level 46-48: Arcane Focus (3/5) - Arcane
    [46] = {1, 1, 2},  -- Arcane Focus 1/5
    [47] = {1, 1, 2},  -- Arcane Focus 2/5
    [48] = {1, 1, 2},  -- Arcane Focus 3/5

    -- Level 49-53: Arcane Concentration (5/5) - Arcane
    [49] = {1, 2, 1},  -- Arcane Concentration 1/5
    [50] = {1, 2, 1},  -- Arcane Concentration 2/5
    [51] = {1, 2, 1},  -- Arcane Concentration 3/5
    [52] = {1, 2, 1},  -- Arcane Concentration 4/5
    [53] = {1, 2, 1},  -- Arcane Concentration 5/5

    -- Level 54: Arcane Resilience (1/1) - Arcane
    [54] = {1, 2, 4},  -- Arcane Resilience 1/1

    -- Level 55-56: Wand Specialization (2/2) - Arcane
    [55] = {1, 1, 4},  -- Wand Specialization 1/2
    [56] = {1, 1, 4},  -- Wand Specialization 2/2

    -- Level 57-59: Arcane Meditation (3/3) - Arcane
    [57] = {1, 3, 2},  -- Arcane Meditation 1/3
    [58] = {1, 3, 2},  -- Arcane Meditation 2/3
    [59] = {1, 3, 2},  -- Arcane Meditation 3/3

    -- Level 60: Improved Arcane Explosion (1/3) - Arcane
    [60] = {1, 3, 3},  -- Improved Arcane Explosion 1/3
})

-- AoE Grinding Frost Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/aoe-grinding-frost-mage-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("MAGE", "Frost AoE Grinding (Icy Veins)", "leveling", {
    -- Level 10-12: Elemental Precision (3/3) - Frost (via Arcane)
    [10] = {1, 4, 1},  -- Elemental Precision 1/3
    [11] = {1, 4, 1},  -- Elemental Precision 2/3
    [12] = {1, 4, 1},  -- Elemental Precision 3/3

    -- Level 13-14: Frost Warding (2/2) - Frost
    [13] = {3, 1, 1},  -- Frost Warding 1/2
    [14] = {3, 1, 1},  -- Frost Warding 2/2

    -- Level 15-16: Improved Frost Nova (2/2) - Frost
    [15] = {3, 2, 4},  -- Improved Frost Nova 1/2
    [16] = {3, 2, 4},  -- Improved Frost Nova 2/2

    -- Level 17-19: Permafrost (3/3) - Frost
    [17] = {3, 2, 2},  -- Permafrost 1/3
    [18] = {3, 2, 2},  -- Permafrost 2/3
    [19] = {3, 2, 2},  -- Permafrost 3/3

    -- Level 20-22: Improved Blizzard (3/3) - Frost
    [20] = {3, 3, 2},  -- Improved Blizzard 1/3
    [21] = {3, 3, 2},  -- Improved Blizzard 2/3
    [22] = {3, 3, 2},  -- Improved Blizzard 3/3

    -- Level 23: Cold Snap (1/1) - Frost
    [23] = {3, 3, 1},  -- Cold Snap 1/1

    -- Level 24: Piercing Ice (1/3) - Frost
    [24] = {3, 2, 3},  -- Piercing Ice 1/3

    -- Level 25-27: Frost Channeling (3/3) - Frost
    [25] = {3, 4, 3},  -- Frost Channeling 1/3
    [26] = {3, 4, 3},  -- Frost Channeling 2/3
    [27] = {3, 4, 3},  -- Frost Channeling 3/3

    -- Level 28-29: Arctic Reach (2/2) - Frost
    [28] = {3, 4, 1},  -- Arctic Reach 1/2
    [29] = {3, 4, 1},  -- Arctic Reach 2/2

    -- Level 30: Ice Block (1/1) - Frost
    [30] = {3, 5, 2},  -- Ice Block 1/1

    -- Level 31-32: Piercing Ice (3/3) - Frost
    [31] = {3, 2, 3},  -- Piercing Ice 2/3
    [32] = {3, 2, 3},  -- Piercing Ice 3/3

    -- Level 33-35: Improved Cone of Cold (3/3) - Frost
    [33] = {3, 4, 2},  -- Improved Cone of Cold 1/3
    [34] = {3, 4, 2},  -- Improved Cone of Cold 2/3
    [35] = {3, 4, 2},  -- Improved Cone of Cold 3/3

    -- Level 36-39: Ice Shards (4/5) - Frost
    [36] = {3, 1, 3},  -- Ice Shards 1/5
    [37] = {3, 1, 3},  -- Ice Shards 2/5
    [38] = {3, 1, 3},  -- Ice Shards 3/5
    [39] = {3, 1, 3},  -- Ice Shards 4/5

    -- Level 40: Ice Barrier (1/1) - Frost
    [40] = {3, 7, 2},  -- Ice Barrier 1/1

    -- Level 41-43: Arcane Focus (3/5) - Arcane
    [41] = {1, 1, 2},  -- Arcane Focus 1/5
    [42] = {1, 1, 2},  -- Arcane Focus 2/5
    [43] = {1, 1, 2},  -- Arcane Focus 3/5

    -- Level 44-45: Arcane Subtlety (2/2) - Arcane
    [44] = {1, 1, 1},  -- Arcane Subtlety 1/2
    [45] = {1, 1, 1},  -- Arcane Subtlety 2/2

    -- Level 46-50: Arcane Concentration (5/5) - Arcane
    [46] = {1, 2, 1},  -- Arcane Concentration 1/5
    [47] = {1, 2, 1},  -- Arcane Concentration 2/5
    [48] = {1, 2, 1},  -- Arcane Concentration 3/5
    [49] = {1, 2, 1},  -- Arcane Concentration 4/5
    [50] = {1, 2, 1},  -- Arcane Concentration 5/5

    -- Level 51: Arcane Resilience (1/1) - Arcane
    [51] = {1, 2, 4},  -- Arcane Resilience 1/1

    -- Level 52-54: Improved Arcane Explosion (3/3) - Arcane
    [52] = {1, 3, 3},  -- Improved Arcane Explosion 1/3
    [53] = {1, 3, 3},  -- Improved Arcane Explosion 2/3
    [54] = {1, 3, 3},  -- Improved Arcane Explosion 3/3

    -- Level 55: Wand Specialization (1/2) - Arcane
    [55] = {1, 1, 4},  -- Wand Specialization 1/2

    -- Level 56-58: Arcane Meditation (3/3) - Arcane
    [56] = {1, 3, 2},  -- Arcane Meditation 1/3
    [57] = {1, 3, 2},  -- Arcane Meditation 2/3
    [58] = {1, 3, 2},  -- Arcane Meditation 3/3

    -- Level 59: Ice Shards (5/5) - Frost
    [59] = {3, 1, 3},  -- Ice Shards 5/5

    -- Level 60: Wand Specialization (2/2) - Arcane
    [60] = {1, 1, 4},  -- Wand Specialization 2/2
})

-- Arcane Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/arcane-mage-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("MAGE", "Arcane (Icy Veins)", "leveling", {
    -- Level 10-11: Arcane Focus (2/5) - Arcane
    [10] = {1, 1, 2},  -- Arcane Focus 1/5
    [11] = {1, 1, 2},  -- Arcane Focus 2/5

    -- Level 12-14: Improved Arcane Missiles (3/5) - Arcane
    [12] = {1, 2, 2},  -- Improved Arcane Missiles 1/5
    [13] = {1, 2, 2},  -- Improved Arcane Missiles 2/5
    [14] = {1, 2, 2},  -- Improved Arcane Missiles 3/5

    -- Level 15-16: Wand Specialization (2/2) - Arcane
    [15] = {1, 1, 4},  -- Wand Specialization 1/2
    [16] = {1, 1, 4},  -- Wand Specialization 2/2

    -- Level 17-18: Improved Arcane Missiles (5/5) - Arcane
    [17] = {1, 2, 2},  -- Improved Arcane Missiles 4/5
    [18] = {1, 2, 2},  -- Improved Arcane Missiles 5/5

    -- Level 19: Arcane Concentration (1/5) - Arcane
    [19] = {1, 2, 1},  -- Arcane Concentration 1/5

    -- Level 20: Arcane Resilience (1/1) - Arcane
    [20] = {1, 2, 4},  -- Arcane Resilience 1/1

    -- Level 21-23: Improved Arcane Explosion (3/3) - Arcane
    [21] = {1, 3, 3},  -- Improved Arcane Explosion 1/3
    [22] = {1, 3, 3},  -- Improved Arcane Explosion 2/3
    [23] = {1, 3, 3},  -- Improved Arcane Explosion 3/3

    -- Level 24-27: Arcane Concentration (5/5) - Arcane
    [24] = {1, 2, 1},  -- Arcane Concentration 2/5
    [25] = {1, 2, 1},  -- Arcane Concentration 3/5
    [26] = {1, 2, 1},  -- Arcane Concentration 4/5
    [27] = {1, 2, 1},  -- Arcane Concentration 5/5

    -- Level 28-30: Arcane Meditation (3/3) - Arcane
    [28] = {1, 3, 2},  -- Arcane Meditation 1/3
    [29] = {1, 3, 2},  -- Arcane Meditation 2/3
    [30] = {1, 3, 2},  -- Arcane Meditation 3/3

    -- Level 31: Presence of Mind (1/1) - Arcane
    [31] = {1, 5, 2},  -- Presence of Mind 1/1

    -- Level 32-36: Arcane Mind (5/5) - Arcane
    [32] = {1, 4, 2},  -- Arcane Mind 1/5
    [33] = {1, 4, 2},  -- Arcane Mind 2/5
    [34] = {1, 4, 2},  -- Arcane Mind 3/5
    [35] = {1, 4, 2},  -- Arcane Mind 4/5
    [36] = {1, 4, 2},  -- Arcane Mind 5/5

    -- Level 37-39: Arcane Instability (3/3) - Arcane
    [37] = {1, 6, 2},  -- Arcane Instability 1/3
    [38] = {1, 6, 2},  -- Arcane Instability 2/3
    [39] = {1, 6, 2},  -- Arcane Instability 3/3

    -- Level 40: Arcane Power (1/1) - Arcane
    [40] = {1, 7, 2},  -- Arcane Power 1/1

    -- Level 41-43: Elemental Precision (3/3) - Arcane
    [41] = {1, 4, 1},  -- Elemental Precision 1/3
    [42] = {1, 4, 1},  -- Elemental Precision 2/3
    [43] = {1, 4, 1},  -- Elemental Precision 3/3

    -- Level 44-48: Improved Frostbolt (5/5) - Frost
    [44] = {3, 1, 2},  -- Improved Frostbolt 1/5
    [45] = {3, 1, 2},  -- Improved Frostbolt 2/5
    [46] = {3, 1, 2},  -- Improved Frostbolt 3/5
    [47] = {3, 1, 2},  -- Improved Frostbolt 4/5
    [48] = {3, 1, 2},  -- Improved Frostbolt 5/5

    -- Level 49-53: Ice Shards (5/5) - Frost
    [49] = {3, 1, 3},  -- Ice Shards 1/5
    [50] = {3, 1, 3},  -- Ice Shards 2/5
    [51] = {3, 1, 3},  -- Ice Shards 3/5
    [52] = {3, 1, 3},  -- Ice Shards 4/5
    [53] = {3, 1, 3},  -- Ice Shards 5/5

    -- Level 54-56: Piercing Ice (3/3) - Frost
    [54] = {3, 2, 3},  -- Piercing Ice 1/3
    [55] = {3, 2, 3},  -- Piercing Ice 2/3
    [56] = {3, 2, 3},  -- Piercing Ice 3/3

    -- Level 57-59: Frost Channeling (3/3) - Frost
    [57] = {3, 4, 3},  -- Frost Channeling 1/3
    [58] = {3, 4, 3},  -- Frost Channeling 2/3
    [59] = {3, 4, 3},  -- Frost Channeling 3/3

    -- Level 60: Arctic Reach (1/2) - Frost
    [60] = {3, 4, 1},  -- Arctic Reach 1/2
})
