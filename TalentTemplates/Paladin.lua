--[[
Guidelime Vanilla - Talent Templates

Paladin talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Holy
2 = Protection
3 = Retribution

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Retribution Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/retribution-paladin-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("PALADIN", "Retribution (Icy Veins)", "leveling", {
    -- Level 10-14: Benediction (5/5) - Retribution
    [10] = {3, 1, 2},  -- Benediction 1/5
    [11] = {3, 1, 2},  -- Benediction 2/5
    [12] = {3, 1, 2},  -- Benediction 3/5
    [13] = {3, 1, 2},  -- Benediction 4/5
    [14] = {3, 1, 2},  -- Benediction 5/5

    -- Level 15-16: Improved Judgement (2/2) - Retribution
    [15] = {3, 1, 3},  -- Improved Judgement 1/2
    [16] = {3, 1, 3},  -- Improved Judgement 2/2

    -- Level 17-19: Deflection (3/5) - Retribution
    [17] = {3, 2, 1},  -- Deflection 1/5
    [18] = {3, 2, 1},  -- Deflection 2/5
    [19] = {3, 2, 1},  -- Deflection 3/5

    -- Level 20-21: Pursuit of Justice (2/2) - Retribution
    [20] = {3, 3, 4},  -- Pursuit of Justice 1/2
    [21] = {3, 3, 4},  -- Pursuit of Justice 2/2

    -- Level 22: Seal of Command (1/1) - Retribution
    [22] = {3, 3, 2},  -- Seal of Command 1/1

    -- Level 23-27: Conviction (5/5) - Retribution
    [23] = {3, 3, 3},  -- Conviction 1/5
    [24] = {3, 3, 3},  -- Conviction 2/5
    [25] = {3, 3, 3},  -- Conviction 3/5
    [26] = {3, 3, 3},  -- Conviction 4/5
    [27] = {3, 3, 3},  -- Conviction 5/5

    -- Level 28-29: Deflection (5/5) - Retribution
    [28] = {3, 2, 1},  -- Deflection 4/5
    [29] = {3, 2, 1},  -- Deflection 5/5

    -- Level 30: Sanctity Aura (1/1) - Retribution
    [30] = {3, 5, 1},  -- Sanctity Aura 1/1

    -- Level 31-33: Two-Handed Weapon Specialization (3/3) - Retribution
    [31] = {3, 4, 3},  -- Two-Handed Weapon Specialization 1/3
    [32] = {3, 4, 3},  -- Two-Handed Weapon Specialization 2/3
    [33] = {3, 4, 3},  -- Two-Handed Weapon Specialization 3/3

    -- Level 34: Improved Blessing of Might (1/5) - Holy
    [34] = {1, 1, 2},  -- Improved Blessing of Might 1/5

    -- Level 35-39: Vengeance (5/5) - Retribution
    [35] = {3, 5, 3},  -- Vengeance 1/5
    [36] = {3, 5, 3},  -- Vengeance 2/5
    [37] = {3, 5, 3},  -- Vengeance 3/5
    [38] = {3, 5, 3},  -- Vengeance 4/5
    [39] = {3, 5, 3},  -- Vengeance 5/5

    -- Level 40: Repentance (1/1) - Retribution
    [40] = {3, 7, 2},  -- Repentance 1/1

    -- Level 41-45: Divine Strength (5/5) - Holy
    [41] = {1, 1, 1},  -- Divine Strength 1/5
    [42] = {1, 1, 1},  -- Divine Strength 2/5
    [43] = {1, 1, 1},  -- Divine Strength 3/5
    [44] = {1, 1, 1},  -- Divine Strength 4/5
    [45] = {1, 1, 1},  -- Divine Strength 5/5

    -- Level 46-50: Improved Seal of Righteousness (5/5) - Holy
    [46] = {1, 2, 4},  -- Improved Seal of Righteousness 1/5
    [47] = {1, 2, 4},  -- Improved Seal of Righteousness 2/5
    [48] = {1, 2, 4},  -- Improved Seal of Righteousness 3/5
    [49] = {1, 2, 4},  -- Improved Seal of Righteousness 4/5
    [50] = {1, 2, 4},  -- Improved Seal of Righteousness 5/5

    -- Level 51: Consecration (1/1) - Holy
    [51] = {1, 3, 2},  -- Consecration 1/1

    -- Level 52-54: Healing Light (3/3) - Holy
    [52] = {1, 2, 1},  -- Healing Light 1/3
    [53] = {1, 2, 1},  -- Healing Light 2/3
    [54] = {1, 2, 1},  -- Healing Light 3/3

    -- Level 55-58: Improved Blessing of Might (5/5) - Holy
    [55] = {1, 1, 2},  -- Improved Blessing of Might 2/5
    [56] = {1, 1, 2},  -- Improved Blessing of Might 3/5
    [57] = {1, 1, 2},  -- Improved Blessing of Might 4/5
    [58] = {1, 1, 2},  -- Improved Blessing of Might 5/5

    -- Level 59-60: Improved Lay on Hands (2/2) - Holy
    [59] = {1, 2, 3},  -- Improved Lay on Hands 1/2
    [60] = {1, 2, 3},  -- Improved Lay on Hands 2/2
})

-- Protection Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/protection-paladin-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("PALADIN", "Protection (Icy Veins)", "leveling", {
    -- Level 10-14: Divine Intellect (5/5) - Holy
    [10] = {1, 1, 3},  -- Divine Intellect 1/5
    [11] = {1, 1, 3},  -- Divine Intellect 2/5
    [12] = {1, 1, 3},  -- Divine Intellect 3/5
    [13] = {1, 1, 3},  -- Divine Intellect 4/5
    [14] = {1, 1, 3},  -- Divine Intellect 5/5

    -- Level 15-19: Improved Seal of Righteousness (5/5) - Holy
    [15] = {1, 2, 4},  -- Improved Seal of Righteousness 1/5
    [16] = {1, 2, 4},  -- Improved Seal of Righteousness 2/5
    [17] = {1, 2, 4},  -- Improved Seal of Righteousness 3/5
    [18] = {1, 2, 4},  -- Improved Seal of Righteousness 4/5
    [19] = {1, 2, 4},  -- Improved Seal of Righteousness 5/5

    -- Level 20: Consecration (1/1) - Holy
    [20] = {1, 3, 2},  -- Consecration 1/1

    -- Level 21-25: Redoubt (5/5) - Protection
    [21] = {2, 1, 2},  -- Redoubt 1/5
    [22] = {2, 1, 2},  -- Redoubt 2/5
    [23] = {2, 1, 2},  -- Redoubt 3/5
    [24] = {2, 1, 2},  -- Redoubt 4/5
    [25] = {2, 1, 2},  -- Redoubt 5/5

    -- Level 26-28: Precision (3/3) - Protection
    [26] = {2, 2, 1},  -- Precision 1/3
    [27] = {2, 2, 1},  -- Precision 2/3
    [28] = {2, 2, 1},  -- Precision 3/3

    -- Level 29-30: Guardian's Favor (2/2) - Protection
    [29] = {2, 2, 2},  -- Guardian's Favor 1/2
    [30] = {2, 2, 2},  -- Guardian's Favor 2/2

    -- Level 31-33: Improved Righteous Fury (3/3) - Protection
    [31] = {2, 4, 3},  -- Improved Righteous Fury 1/3
    [32] = {2, 4, 3},  -- Improved Righteous Fury 2/3
    [33] = {2, 4, 3},  -- Improved Righteous Fury 3/3

    -- Level 34-38: Anticipation (5/5) - Protection
    [34] = {2, 2, 4},  -- Anticipation 1/5
    [35] = {2, 2, 4},  -- Anticipation 2/5
    [36] = {2, 2, 4},  -- Anticipation 3/5
    [37] = {2, 2, 4},  -- Anticipation 4/5
    [38] = {2, 2, 4},  -- Anticipation 5/5

    -- Level 39-41: Shield Specialization (3/3) - Protection
    [39] = {2, 3, 3},  -- Shield Specialization 1/3
    [40] = {2, 3, 3},  -- Shield Specialization 2/3
    [41] = {2, 3, 3},  -- Shield Specialization 3/3

    -- Level 42: Blessing of Sanctuary (1/1) - Protection
    [42] = {2, 5, 2},  -- Blessing of Sanctuary 1/1

    -- Level 43-45: Reckoning (3/5) - Protection
    [43] = {2, 4, 2},  -- Reckoning 1/5
    [44] = {2, 4, 2},  -- Reckoning 2/5
    [45] = {2, 4, 2},  -- Reckoning 3/5

    -- Level 46-50: One-Handed Weapon Specialization (5/5) - Protection
    [46] = {2, 5, 3},  -- One-Handed Weapon Specialization 1/5
    [47] = {2, 5, 3},  -- One-Handed Weapon Specialization 2/5
    [48] = {2, 5, 3},  -- One-Handed Weapon Specialization 3/5
    [49] = {2, 5, 3},  -- One-Handed Weapon Specialization 4/5
    [50] = {2, 5, 3},  -- One-Handed Weapon Specialization 5/5

    -- Level 51: Holy Shield (1/1) - Protection
    [51] = {2, 7, 2},  -- Holy Shield 1/1

    -- Level 52-56: Benediction (5/5) - Retribution
    [52] = {3, 1, 2},  -- Benediction 1/5
    [53] = {3, 1, 2},  -- Benediction 2/5
    [54] = {3, 1, 2},  -- Benediction 3/5
    [55] = {3, 1, 2},  -- Benediction 4/5
    [56] = {3, 1, 2},  -- Benediction 5/5

    -- Level 57-58: Improved Judgement (2/2) - Retribution
    [57] = {3, 1, 3},  -- Improved Judgement 1/2
    [58] = {3, 1, 3},  -- Improved Judgement 2/2

    -- Level 59-60: Deflection (2/5) - Retribution
    [59] = {3, 2, 1},  -- Deflection 1/5
    [60] = {3, 2, 1},  -- Deflection 2/5
})

-- Holy Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/holy-paladin-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("PALADIN", "Holy (Icy Veins)", "leveling", {
    -- Level 10-14: Divine Intellect (5/5) - Holy
    [10] = {1, 1, 3},  -- Divine Intellect 1/5
    [11] = {1, 1, 3},  -- Divine Intellect 2/5
    [12] = {1, 1, 3},  -- Divine Intellect 3/5
    [13] = {1, 1, 3},  -- Divine Intellect 4/5
    [14] = {1, 1, 3},  -- Divine Intellect 5/5

    -- Level 15-19: Spiritual Focus (5/5) - Holy
    [15] = {1, 2, 2},  -- Spiritual Focus 1/5
    [16] = {1, 2, 2},  -- Spiritual Focus 2/5
    [17] = {1, 2, 2},  -- Spiritual Focus 3/5
    [18] = {1, 2, 2},  -- Spiritual Focus 4/5
    [19] = {1, 2, 2},  -- Spiritual Focus 5/5

    -- Level 20: Consecration (1/1) - Holy
    [20] = {1, 3, 2},  -- Consecration 1/1

    -- Level 21-23: Healing Light (3/3) - Holy
    [21] = {1, 2, 1},  -- Healing Light 1/3
    [22] = {1, 2, 1},  -- Healing Light 2/3
    [23] = {1, 2, 1},  -- Healing Light 3/3

    -- Level 24: Improved Lay on Hands (1/2) - Holy
    [24] = {1, 2, 3},  -- Improved Lay on Hands 1/2

    -- Level 25-26: Improved Blessing of Wisdom (2/2) - Holy
    [25] = {1, 3, 4},  -- Improved Blessing of Wisdom 1/2
    [26] = {1, 3, 4},  -- Improved Blessing of Wisdom 2/2

    -- Level 27-31: Illumination (5/5) - Holy
    [27] = {1, 4, 2},  -- Illumination 1/5
    [28] = {1, 4, 2},  -- Illumination 2/5
    [29] = {1, 4, 2},  -- Illumination 3/5
    [30] = {1, 4, 2},  -- Illumination 4/5
    [31] = {1, 4, 2},  -- Illumination 5/5

    -- Level 32: Divine Favor (1/1) - Holy
    [32] = {1, 5, 2},  -- Divine Favor 1/1

    -- Level 33-34: Lasting Judgement (2/3) - Holy
    [33] = {1, 4, 4},  -- Lasting Judgement 1/3
    [34] = {1, 4, 4},  -- Lasting Judgement 2/3

    -- Level 35-39: Holy Power (5/5) - Holy
    [35] = {1, 5, 3},  -- Holy Power 1/5
    [36] = {1, 5, 3},  -- Holy Power 2/5
    [37] = {1, 5, 3},  -- Holy Power 3/5
    [38] = {1, 5, 3},  -- Holy Power 4/5
    [39] = {1, 5, 3},  -- Holy Power 5/5

    -- Level 40: Holy Shock (1/1) - Holy
    [40] = {1, 7, 2},  -- Holy Shock 1/1

    -- Level 41-45: Benediction (5/5) - Retribution
    [41] = {3, 1, 2},  -- Benediction 1/5
    [42] = {3, 1, 2},  -- Benediction 2/5
    [43] = {3, 1, 2},  -- Benediction 3/5
    [44] = {3, 1, 2},  -- Benediction 4/5
    [45] = {3, 1, 2},  -- Benediction 5/5

    -- Level 46-50: Improved Blessing of Might (5/5) - Retribution
    [46] = {3, 1, 1},  -- Improved Blessing of Might 1/5
    [47] = {3, 1, 1},  -- Improved Blessing of Might 2/5
    [48] = {3, 1, 1},  -- Improved Blessing of Might 3/5
    [49] = {3, 1, 1},  -- Improved Blessing of Might 4/5
    [50] = {3, 1, 1},  -- Improved Blessing of Might 5/5

    -- Level 51-52: Pursuit of Justice (2/2) - Retribution
    [51] = {3, 3, 4},  -- Pursuit of Justice 1/2
    [52] = {3, 3, 4},  -- Pursuit of Justice 2/2

    -- Level 53-57: Improved Devotion Aura (5/5) - Protection
    [53] = {2, 1, 1},  -- Improved Devotion Aura 1/5
    [54] = {2, 1, 1},  -- Improved Devotion Aura 2/5
    [55] = {2, 1, 1},  -- Improved Devotion Aura 3/5
    [56] = {2, 1, 1},  -- Improved Devotion Aura 4/5
    [57] = {2, 1, 1},  -- Improved Devotion Aura 5/5

    -- Level 58-59: Guardian's Favor (2/2) - Protection
    [58] = {2, 2, 2},  -- Guardian's Favor 1/2
    [59] = {2, 2, 2},  -- Guardian's Favor 2/2

    -- Level 60: Improved Lay on Hands (2/2) - Holy
    [60] = {1, 2, 3},  -- Improved Lay on Hands 2/2
})
