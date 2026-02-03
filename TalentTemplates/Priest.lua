--[[
Guidelime Vanilla - Talent Templates

Priest talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Discipline
2 = Holy
3 = Shadow

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Shadow Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/shadow-priest-leveling-talent-build-from-1-to-60
-- Note: This build starts Discipline, respec to Shadow at level 40
GLV:RegisterTalentTemplate("PRIEST", "Shadow (Icy Veins)", "leveling", {
    -- Level 10-14: Wand Specialization (5/5) - Discipline
    [10] = {1, 1, 3},  -- Wand Specialization 1/5
    [11] = {1, 1, 3},  -- Wand Specialization 2/5
    [12] = {1, 1, 3},  -- Wand Specialization 3/5
    [13] = {1, 1, 3},  -- Wand Specialization 4/5
    [14] = {1, 1, 3},  -- Wand Specialization 5/5

    -- Level 15-19: Spirit Tap (5/5) - Shadow
    [15] = {3, 1, 1},  -- Spirit Tap 1/5
    [16] = {3, 1, 1},  -- Spirit Tap 2/5
    [17] = {3, 1, 1},  -- Spirit Tap 3/5
    [18] = {3, 1, 1},  -- Spirit Tap 4/5
    [19] = {3, 1, 1},  -- Spirit Tap 5/5

    -- Level 20-22: Improved Power Word: Shield (3/3) - Discipline
    [20] = {1, 2, 1},  -- Improved Power Word: Shield 1/3
    [21] = {1, 2, 1},  -- Improved Power Word: Shield 2/3
    [22] = {1, 2, 1},  -- Improved Power Word: Shield 3/3

    -- Level 23-24: Improved Power Word: Fortitude (2/2) - Discipline
    [23] = {1, 2, 2},  -- Improved Power Word: Fortitude 1/2
    [24] = {1, 2, 2},  -- Improved Power Word: Fortitude 2/2

    -- Level 25: Inner Focus (1/1) - Discipline
    [25] = {1, 5, 2},  -- Inner Focus 1/1

    -- Level 26-28: Meditation (3/3) - Discipline
    [26] = {1, 3, 1},  -- Meditation 1/3
    [27] = {1, 3, 1},  -- Meditation 2/3
    [28] = {1, 3, 1},  -- Meditation 3/3

    -- Level 29: Unbreakable Will (1/5) - Discipline
    [29] = {1, 1, 1},  -- Unbreakable Will 1/5

    -- Level 30-32: Improved Inner Fire (3/3) - Discipline
    [30] = {1, 2, 4},  -- Improved Inner Fire 1/3
    [31] = {1, 2, 4},  -- Improved Inner Fire 2/3
    [32] = {1, 2, 4},  -- Improved Inner Fire 3/3

    -- Level 33-35: Mental Agility (3/5) - Discipline
    [33] = {1, 4, 2},  -- Mental Agility 1/5
    [34] = {1, 4, 2},  -- Mental Agility 2/5
    [35] = {1, 4, 2},  -- Mental Agility 3/5

    -- Level 36: Divine Spirit (1/1) - Discipline
    [36] = {1, 5, 3},  -- Divine Spirit 1/1

    -- Level 37-39: Mental Agility (5/5) - Discipline
    [37] = {1, 4, 2},  -- Mental Agility 4/5
    [38] = {1, 4, 2},  -- Mental Agility 5/5
    [39] = {1, 4, 3},  -- Mental Strength 1/5

    -- At level 40+, the guide suggests respeccing to full Shadow
    -- Level 40-44: Shadow Focus (5/5) - Shadow
    [40] = {3, 2, 2},  -- Shadow Focus 1/5
    [41] = {3, 2, 2},  -- Shadow Focus 2/5
    [42] = {3, 2, 2},  -- Shadow Focus 3/5
    [43] = {3, 2, 2},  -- Shadow Focus 4/5
    [44] = {3, 2, 2},  -- Shadow Focus 5/5

    -- Level 45-49: Darkness (5/5) - Shadow
    [45] = {3, 6, 2},  -- Darkness 1/5
    [46] = {3, 6, 2},  -- Darkness 2/5
    [47] = {3, 6, 2},  -- Darkness 3/5
    [48] = {3, 6, 2},  -- Darkness 4/5
    [49] = {3, 6, 2},  -- Darkness 5/5

    -- Level 50: Shadowform (1/1) - Shadow
    [50] = {3, 7, 2},  -- Shadowform 1/1

    -- Level 51-55: Shadow Weaving (5/5) - Shadow
    [51] = {3, 4, 3},  -- Shadow Weaving 1/5
    [52] = {3, 4, 3},  -- Shadow Weaving 2/5
    [53] = {3, 4, 3},  -- Shadow Weaving 3/5
    [54] = {3, 4, 3},  -- Shadow Weaving 4/5
    [55] = {3, 4, 3},  -- Shadow Weaving 5/5

    -- Level 56: Vampiric Embrace (1/1) - Shadow
    [56] = {3, 5, 2},  -- Vampiric Embrace 1/1

    -- Level 57-59: Improved Mind Blast (3/5) - Shadow
    [57] = {3, 2, 3},  -- Improved Mind Blast 1/5
    [58] = {3, 2, 3},  -- Improved Mind Blast 2/5
    [59] = {3, 2, 3},  -- Improved Mind Blast 3/5

    -- Level 60: Mind Flay (1/1) - Shadow
    [60] = {3, 3, 2},  -- Mind Flay 1/1
})

-- Holy Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/holy-priest-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("PRIEST", "Holy (Icy Veins)", "leveling", {
    -- Level 10-14: Wand Specialization (5/5) - Holy (actually Discipline)
    [10] = {1, 1, 3},  -- Wand Specialization 1/5
    [11] = {1, 1, 3},  -- Wand Specialization 2/5
    [12] = {1, 1, 3},  -- Wand Specialization 3/5
    [13] = {1, 1, 3},  -- Wand Specialization 4/5
    [14] = {1, 1, 3},  -- Wand Specialization 5/5

    -- Level 15-19: Spirit Tap (5/5) - Shadow
    [15] = {3, 1, 1},  -- Spirit Tap 1/5
    [16] = {3, 1, 1},  -- Spirit Tap 2/5
    [17] = {3, 1, 1},  -- Spirit Tap 3/5
    [18] = {3, 1, 1},  -- Spirit Tap 4/5
    [19] = {3, 1, 1},  -- Spirit Tap 5/5

    -- Level 20-21: Healing Focus (2/2) - Holy
    [20] = {2, 1, 1},  -- Healing Focus 1/2
    [21] = {2, 1, 1},  -- Healing Focus 2/2

    -- Level 22-24: Improved Renew (3/3) - Holy
    [22] = {2, 1, 2},  -- Improved Renew 1/3
    [23] = {2, 1, 2},  -- Improved Renew 2/3
    [24] = {2, 1, 2},  -- Improved Renew 3/3

    -- Level 25-29: Divine Fury (5/5) - Holy
    [25] = {2, 2, 2},  -- Divine Fury 1/5
    [26] = {2, 2, 2},  -- Divine Fury 2/5
    [27] = {2, 2, 2},  -- Divine Fury 3/5
    [28] = {2, 2, 2},  -- Divine Fury 4/5
    [29] = {2, 2, 2},  -- Divine Fury 5/5

    -- Level 30: Holy Nova (1/1) - Holy
    [30] = {2, 3, 4},  -- Holy Nova 1/1

    -- Level 31-35: Holy Specialization (5/5) - Holy
    [31] = {2, 1, 3},  -- Holy Specialization 1/5
    [32] = {2, 1, 3},  -- Holy Specialization 2/5
    [33] = {2, 1, 3},  -- Holy Specialization 3/5
    [34] = {2, 1, 3},  -- Holy Specialization 4/5
    [35] = {2, 1, 3},  -- Holy Specialization 5/5

    -- Level 36-37: Searing Light (2/2) - Holy
    [36] = {2, 4, 2},  -- Searing Light 1/2
    [37] = {2, 4, 2},  -- Searing Light 2/2

    -- Level 38-39: Holy Reach (2/2) - Holy
    [38] = {2, 3, 2},  -- Holy Reach 1/2
    [39] = {2, 3, 2},  -- Holy Reach 2/2

    -- Level 40-42: Improved Power Word: Shield (3/3) - Discipline
    [40] = {1, 2, 1},  -- Improved Power Word: Shield 1/3
    [41] = {1, 2, 1},  -- Improved Power Word: Shield 2/3
    [42] = {1, 2, 1},  -- Improved Power Word: Shield 3/3

    -- Level 43-44: Improved Power Word: Fortitude (2/2) - Discipline
    [43] = {1, 2, 2},  -- Improved Power Word: Fortitude 1/2
    [44] = {1, 2, 2},  -- Improved Power Word: Fortitude 2/2

    -- Level 45: Inner Focus (1/1) - Discipline
    [45] = {1, 5, 2},  -- Inner Focus 1/1

    -- Level 46-48: Meditation (3/3) - Discipline
    [46] = {1, 3, 1},  -- Meditation 1/3
    [47] = {1, 3, 1},  -- Meditation 2/3
    [48] = {1, 3, 1},  -- Meditation 3/3

    -- Level 49: Improved Healing (1/3) - Holy
    [49] = {2, 4, 1},  -- Improved Healing 1/3

    -- Level 50-54: Spiritual Guidance (5/5) - Holy
    [50] = {2, 6, 3},  -- Spiritual Guidance 1/5
    [51] = {2, 6, 3},  -- Spiritual Guidance 2/5
    [52] = {2, 6, 3},  -- Spiritual Guidance 3/5
    [53] = {2, 6, 3},  -- Spiritual Guidance 4/5
    [54] = {2, 6, 3},  -- Spiritual Guidance 5/5

    -- Level 55-56: Improved Healing (3/3) - Holy
    [55] = {2, 4, 1},  -- Improved Healing 2/3
    [56] = {2, 4, 1},  -- Improved Healing 3/3

    -- Level 57-60: Spiritual Healing (4/5) - Holy
    [57] = {2, 5, 3},  -- Spiritual Healing 1/5
    [58] = {2, 5, 3},  -- Spiritual Healing 2/5
    [59] = {2, 5, 3},  -- Spiritual Healing 3/5
    [60] = {2, 5, 3},  -- Spiritual Healing 4/5
})

-- Discipline Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/discipline-priest-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("PRIEST", "Discipline (Icy Veins)", "leveling", {
    -- Level 10-14: Wand Specialization (5/5) - Discipline
    [10] = {1, 1, 3},  -- Wand Specialization 1/5
    [11] = {1, 1, 3},  -- Wand Specialization 2/5
    [12] = {1, 1, 3},  -- Wand Specialization 3/5
    [13] = {1, 1, 3},  -- Wand Specialization 4/5
    [14] = {1, 1, 3},  -- Wand Specialization 5/5

    -- Level 15-19: Spirit Tap (5/5) - Shadow
    [15] = {3, 1, 1},  -- Spirit Tap 1/5
    [16] = {3, 1, 1},  -- Spirit Tap 2/5
    [17] = {3, 1, 1},  -- Spirit Tap 3/5
    [18] = {3, 1, 1},  -- Spirit Tap 4/5
    [19] = {3, 1, 1},  -- Spirit Tap 5/5

    -- Level 20-22: Improved Power Word: Shield (3/3) - Discipline
    [20] = {1, 2, 1},  -- Improved Power Word: Shield 1/3
    [21] = {1, 2, 1},  -- Improved Power Word: Shield 2/3
    [22] = {1, 2, 1},  -- Improved Power Word: Shield 3/3

    -- Level 23-24: Improved Power Word: Fortitude (2/2) - Discipline
    [23] = {1, 2, 2},  -- Improved Power Word: Fortitude 1/2
    [24] = {1, 2, 2},  -- Improved Power Word: Fortitude 2/2

    -- Level 25: Inner Focus (1/1) - Discipline
    [25] = {1, 5, 2},  -- Inner Focus 1/1

    -- Level 26-28: Meditation (3/3) - Discipline
    [26] = {1, 3, 1},  -- Meditation 1/3
    [27] = {1, 3, 1},  -- Meditation 2/3
    [28] = {1, 3, 1},  -- Meditation 3/3

    -- Level 29: Martyrdom (1/2) - Shadow
    [29] = {1, 3, 2},  -- Martyrdom 1/2

    -- Level 30-34: Mental Agility (5/5) - Discipline
    [30] = {1, 4, 2},  -- Mental Agility 1/5
    [31] = {1, 4, 2},  -- Mental Agility 2/5
    [32] = {1, 4, 2},  -- Mental Agility 3/5
    [33] = {1, 4, 2},  -- Mental Agility 4/5
    [34] = {1, 4, 2},  -- Mental Agility 5/5

    -- Level 35: Divine Spirit (1/1) - Discipline
    [35] = {1, 5, 3},  -- Divine Spirit 1/1

    -- Level 36-40: Mental Strength (5/5) - Discipline
    [36] = {1, 4, 3},  -- Mental Strength 1/5
    [37] = {1, 4, 3},  -- Mental Strength 2/5
    [38] = {1, 4, 3},  -- Mental Strength 3/5
    [39] = {1, 4, 3},  -- Mental Strength 4/5
    [40] = {1, 4, 3},  -- Mental Strength 5/5

    -- Level 41-45: Force of Will (5/5) - Discipline
    [41] = {1, 6, 2},  -- Force of Will 1/5
    [42] = {1, 6, 2},  -- Force of Will 2/5
    [43] = {1, 6, 2},  -- Force of Will 3/5
    [44] = {1, 6, 2},  -- Force of Will 4/5
    [45] = {1, 6, 2},  -- Force of Will 5/5

    -- Level 46: Power Infusion (1/1) - Discipline
    [46] = {1, 7, 2},  -- Power Infusion 1/1

    -- Level 47-48: Healing Focus (2/2) - Holy
    [47] = {2, 1, 1},  -- Healing Focus 1/2
    [48] = {2, 1, 1},  -- Healing Focus 2/2

    -- Level 49-51: Holy Specialization (3/5) - Holy
    [49] = {2, 1, 3},  -- Holy Specialization 1/5
    [50] = {2, 1, 3},  -- Holy Specialization 2/5
    [51] = {2, 1, 3},  -- Holy Specialization 3/5

    -- Level 52-56: Divine Fury (5/5) - Holy
    [52] = {2, 2, 2},  -- Divine Fury 1/5
    [53] = {2, 2, 2},  -- Divine Fury 2/5
    [54] = {2, 2, 2},  -- Divine Fury 3/5
    [55] = {2, 2, 2},  -- Divine Fury 4/5
    [56] = {2, 2, 2},  -- Divine Fury 5/5

    -- Level 57-58: Holy Specialization (5/5) - Holy
    [57] = {2, 1, 3},  -- Holy Specialization 4/5
    [58] = {2, 1, 3},  -- Holy Specialization 5/5

    -- Level 59: Martyrdom (2/2) - Shadow
    [59] = {1, 3, 2},  -- Martyrdom 2/2

    -- Level 60: Holy Nova (1/1) - Holy
    [60] = {2, 3, 4},  -- Holy Nova 1/1
})
