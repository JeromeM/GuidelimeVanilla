--[[
Guidelime Vanilla - Talent Templates

Warlock talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Affliction
2 = Demonology
3 = Destruction

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Affliction/Demonology Hybrid Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/affliction-warlock-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("WARLOCK", "Affliction (Icy Veins)", "leveling", {
    -- Level 10-14: Improved Corruption (5/5) - Affliction
    [10] = {1, 1, 2},  -- Improved Corruption 1/5
    [11] = {1, 1, 2},  -- Improved Corruption 2/5
    [12] = {1, 1, 2},  -- Improved Corruption 3/5
    [13] = {1, 1, 2},  -- Improved Corruption 4/5
    [14] = {1, 1, 2},  -- Improved Corruption 5/5

    -- Level 15-16: Improved Life Tap (2/2) - Affliction
    [15] = {1, 2, 4},  -- Improved Life Tap 1/2
    [16] = {1, 2, 4},  -- Improved Life Tap 2/2

    -- Level 17-18: Suppression (2/5) - Affliction
    [17] = {1, 1, 1},  -- Suppression 1/5
    [18] = {1, 1, 1},  -- Suppression 2/5

    -- Level 19-20: Improved Healthstone (2/2) - Affliction
    [19] = {1, 1, 3},  -- Improved Healthstone 1/2
    [20] = {1, 1, 3},  -- Improved Healthstone 2/2

    -- Level 21-23: Demonic Embrace (3/5) - Demonology
    [21] = {2, 1, 2},  -- Demonic Embrace 1/5
    [22] = {2, 1, 2},  -- Demonic Embrace 2/5
    [23] = {2, 1, 2},  -- Demonic Embrace 3/5

    -- Level 24-26: Improved Voidwalker (3/3) - Demonology
    [24] = {2, 2, 1},  -- Improved Voidwalker 1/3
    [25] = {2, 2, 1},  -- Improved Voidwalker 2/3
    [26] = {2, 2, 1},  -- Improved Voidwalker 3/3

    -- Level 27-28: Improved Drain Soul (2/2) - Affliction
    [27] = {1, 2, 2},  -- Improved Drain Soul 1/2
    [28] = {1, 2, 2},  -- Improved Drain Soul 2/2

    -- Level 29: Amplify Curse (1/1) - Affliction
    [29] = {1, 3, 1},  -- Amplify Curse 1/1

    -- Level 30-32: Suppression (5/5) - Affliction
    [30] = {1, 1, 1},  -- Suppression 3/5
    [31] = {1, 1, 1},  -- Suppression 4/5
    [32] = {1, 1, 1},  -- Suppression 5/5

    -- Level 33-34: Grim Reach (2/2) - Affliction
    [33] = {1, 3, 4},  -- Grim Reach 1/2
    [34] = {1, 3, 4},  -- Grim Reach 2/2

    -- Level 35-36: Nightfall (2/2) - Affliction
    [35] = {1, 4, 2},  -- Nightfall 1/2
    [36] = {1, 4, 2},  -- Nightfall 2/2

    -- Level 37: Improved Curse of Agony (1/3) - Affliction
    [37] = {1, 4, 4},  -- Improved Curse of Agony 1/3

    -- Level 38: Siphon Life (1/1) - Affliction
    [38] = {1, 5, 2},  -- Siphon Life 1/1

    -- Level 39: Curse of Exhaustion (1/1) - Affliction
    [39] = {1, 5, 1},  -- Curse of Exhaustion 1/1

    -- Level 40-41: Improved Curse of Agony (3/3) - Affliction
    [40] = {1, 4, 4},  -- Improved Curse of Agony 2/3
    [41] = {1, 4, 4},  -- Improved Curse of Agony 3/3

    -- Level 42: Improved Curse of Exhaustion (1/4) - Affliction (optional point)
    [42] = {1, 5, 3},  -- Improved Curse of Exhaustion 1/4

    -- Level 43-47: Shadow Mastery (5/5) - Affliction
    [43] = {1, 6, 2},  -- Shadow Mastery 1/5
    [44] = {1, 6, 2},  -- Shadow Mastery 2/5
    [45] = {1, 6, 2},  -- Shadow Mastery 3/5
    [46] = {1, 6, 2},  -- Shadow Mastery 4/5
    [47] = {1, 6, 2},  -- Shadow Mastery 5/5

    -- Level 48-49: Fel Intellect (2/5) - Demonology
    [48] = {2, 2, 3},  -- Fel Intellect 1/5
    [49] = {2, 2, 3},  -- Fel Intellect 2/5

    -- Level 50: Fel Domination (1/1) - Demonology
    [50] = {2, 5, 1},  -- Fel Domination 1/1

    -- Level 51-54: Fel Stamina (4/5) - Demonology
    [51] = {2, 3, 2},  -- Fel Stamina 1/5
    [52] = {2, 3, 2},  -- Fel Stamina 2/5
    [53] = {2, 3, 2},  -- Fel Stamina 3/5
    [54] = {2, 3, 2},  -- Fel Stamina 4/5

    -- Level 55-56: Master Summoner (2/2) - Demonology
    [55] = {2, 5, 2},  -- Master Summoner 1/2
    [56] = {2, 5, 2},  -- Master Summoner 2/2

    -- Level 57-60: Unholy Power (4/5) - Demonology
    [57] = {2, 5, 3},  -- Unholy Power 1/5
    [58] = {2, 5, 3},  -- Unholy Power 2/5
    [59] = {2, 5, 3},  -- Unholy Power 3/5
    [60] = {2, 5, 3},  -- Unholy Power 4/5
})

-- Demonology Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/demonology-warlock-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("WARLOCK", "Demonology (Icy Veins)", "leveling", {
    -- Level 10-14: Improved Corruption (5/5) - Demonology (actually Affliction first)
    [10] = {1, 1, 2},  -- Improved Corruption 1/5
    [11] = {1, 1, 2},  -- Improved Corruption 2/5
    [12] = {1, 1, 2},  -- Improved Corruption 3/5
    [13] = {1, 1, 2},  -- Improved Corruption 4/5
    [14] = {1, 1, 2},  -- Improved Corruption 5/5

    -- Level 15-16: Suppression (2/5) - Affliction
    [15] = {1, 1, 1},  -- Suppression 1/5
    [16] = {1, 1, 1},  -- Suppression 2/5

    -- Level 17-21: Demonic Embrace (5/5) - Demonology
    [17] = {2, 1, 2},  -- Demonic Embrace 1/5
    [18] = {2, 1, 2},  -- Demonic Embrace 2/5
    [19] = {2, 1, 2},  -- Demonic Embrace 3/5
    [20] = {2, 1, 2},  -- Demonic Embrace 4/5
    [21] = {2, 1, 2},  -- Demonic Embrace 5/5

    -- Level 22-24: Improved Voidwalker (3/3) - Demonology
    [22] = {2, 2, 1},  -- Improved Voidwalker 1/3
    [23] = {2, 2, 1},  -- Improved Voidwalker 2/3
    [24] = {2, 2, 1},  -- Improved Voidwalker 3/3

    -- Level 25-26: Improved Healthstone (2/2) - Demonology
    [25] = {2, 1, 3},  -- Improved Healthstone 1/2
    [26] = {2, 1, 3},  -- Improved Healthstone 2/2

    -- Level 27: Fel Domination (1/1) - Demonology
    [27] = {2, 5, 1},  -- Fel Domination 1/1

    -- Level 28-32: Fel Stamina (5/5) - Demonology
    [28] = {2, 3, 2},  -- Fel Stamina 1/5
    [29] = {2, 3, 2},  -- Fel Stamina 2/5
    [30] = {2, 3, 2},  -- Fel Stamina 3/5
    [31] = {2, 3, 2},  -- Fel Stamina 4/5
    [32] = {2, 3, 2},  -- Fel Stamina 5/5

    -- Level 33-34: Master Summoner (2/2) - Demonology
    [33] = {2, 5, 2},  -- Master Summoner 1/2
    [34] = {2, 5, 2},  -- Master Summoner 2/2

    -- Level 35-39: Unholy Power (5/5) - Demonology
    [35] = {2, 5, 3},  -- Unholy Power 1/5
    [36] = {2, 5, 3},  -- Unholy Power 2/5
    [37] = {2, 5, 3},  -- Unholy Power 3/5
    [38] = {2, 5, 3},  -- Unholy Power 4/5
    [39] = {2, 5, 3},  -- Unholy Power 5/5

    -- Level 40: Fel Intellect (1/5) - Demonology
    [40] = {2, 2, 3},  -- Fel Intellect 1/5

    -- Level 41: Demonic Sacrifice (1/1) - Demonology
    [41] = {2, 5, 4},  -- Demonic Sacrifice 1/1

    -- Level 42-46: Master Demonologist (5/5) - Demonology
    [42] = {2, 6, 2},  -- Master Demonologist 1/5
    [43] = {2, 6, 2},  -- Master Demonologist 2/5
    [44] = {2, 6, 2},  -- Master Demonologist 3/5
    [45] = {2, 6, 2},  -- Master Demonologist 4/5
    [46] = {2, 6, 2},  -- Master Demonologist 5/5

    -- Level 47: Soul Link (1/1) - Demonology
    [47] = {2, 7, 2},  -- Soul Link 1/1

    -- Level 48-51: Fel Intellect (5/5) - Demonology
    [48] = {2, 2, 3},  -- Fel Intellect 2/5
    [49] = {2, 2, 3},  -- Fel Intellect 3/5
    [50] = {2, 2, 3},  -- Fel Intellect 4/5
    [51] = {2, 2, 3},  -- Fel Intellect 5/5

    -- Level 52-56: Improved Drain Life (5/5) - Affliction
    [52] = {1, 2, 3},  -- Improved Drain Life 1/5
    [53] = {1, 2, 3},  -- Improved Drain Life 2/5
    [54] = {1, 2, 3},  -- Improved Drain Life 3/5
    [55] = {1, 2, 3},  -- Improved Drain Life 4/5
    [56] = {1, 2, 3},  -- Improved Drain Life 5/5

    -- Level 57-59: Suppression (5/5) - Affliction
    [57] = {1, 1, 1},  -- Suppression 3/5
    [58] = {1, 1, 1},  -- Suppression 4/5
    [59] = {1, 1, 1},  -- Suppression 5/5

    -- Level 60: Improved Life Tap (1/2) - Affliction
    [60] = {1, 2, 4},  -- Improved Life Tap 1/2
})

-- Destruction Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/destruction-warlock-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("WARLOCK", "Destruction (Icy Veins)", "leveling", {
    -- Level 10-14: Cataclysm (5/5) - Destruction
    [10] = {3, 2, 2},  -- Cataclysm 1/5
    [11] = {3, 2, 2},  -- Cataclysm 2/5
    [12] = {3, 2, 2},  -- Cataclysm 3/5
    [13] = {3, 2, 2},  -- Cataclysm 4/5
    [14] = {3, 2, 2},  -- Cataclysm 5/5

    -- Level 15-19: Aftermath (5/5) - Destruction
    [15] = {3, 1, 1},  -- Aftermath 1/5
    [16] = {3, 1, 1},  -- Aftermath 2/5
    [17] = {3, 1, 1},  -- Aftermath 3/5
    [18] = {3, 1, 1},  -- Aftermath 4/5
    [19] = {3, 1, 1},  -- Aftermath 5/5

    -- Level 20: Shadowburn (1/1) - Destruction
    [20] = {3, 3, 4},  -- Shadowburn 1/1

    -- Level 21-25: Devastation (5/5) - Destruction
    [21] = {3, 3, 3},  -- Devastation 1/5
    [22] = {3, 3, 3},  -- Devastation 2/5
    [23] = {3, 3, 3},  -- Devastation 3/5
    [24] = {3, 3, 3},  -- Devastation 4/5
    [25] = {3, 3, 3},  -- Devastation 5/5

    -- Level 26-27: Intensity (2/2) - Destruction
    [26] = {3, 3, 1},  -- Intensity 1/2
    [27] = {3, 3, 1},  -- Intensity 2/2

    -- Level 28-29: Destructive Reach (2/2) - Destruction
    [28] = {3, 3, 2},  -- Destructive Reach 1/2
    [29] = {3, 3, 2},  -- Destructive Reach 2/2

    -- Level 30: Ruin (1/1) - Destruction
    [30] = {3, 5, 2},  -- Ruin 1/1

    -- Level 31-32: Pyroclasm (2/2) - Destruction
    [31] = {3, 4, 3},  -- Pyroclasm 1/2
    [32] = {3, 4, 3},  -- Pyroclasm 2/2

    -- Level 33-34: Improved Immolate (2/5) - Destruction
    [33] = {3, 2, 3},  -- Improved Immolate 1/5
    [34] = {3, 2, 3},  -- Improved Immolate 2/5

    -- Level 35-39: Emberstorm (5/5) - Destruction
    [35] = {3, 5, 3},  -- Emberstorm 1/5
    [36] = {3, 5, 3},  -- Emberstorm 2/5
    [37] = {3, 5, 3},  -- Emberstorm 3/5
    [38] = {3, 5, 3},  -- Emberstorm 4/5
    [39] = {3, 5, 3},  -- Emberstorm 5/5

    -- Level 40-42: Improved Immolate (5/5) - Destruction
    [40] = {3, 2, 3},  -- Improved Immolate 3/5
    [41] = {3, 2, 3},  -- Improved Immolate 4/5
    [42] = {3, 2, 3},  -- Improved Immolate 5/5

    -- Level 43: Conflagrate (1/1) - Destruction
    [43] = {3, 7, 2},  -- Conflagrate 1/1

    -- Level 44-48: Improved Corruption (5/5) - Affliction
    [44] = {1, 1, 2},  -- Improved Corruption 1/5
    [45] = {1, 1, 2},  -- Improved Corruption 2/5
    [46] = {1, 1, 2},  -- Improved Corruption 3/5
    [47] = {1, 1, 2},  -- Improved Corruption 4/5
    [48] = {1, 1, 2},  -- Improved Corruption 5/5

    -- Level 49-50: Improved Life Tap (2/2) - Affliction
    [49] = {1, 2, 4},  -- Improved Life Tap 1/2
    [50] = {1, 2, 4},  -- Improved Life Tap 2/2

    -- Level 51-52: Improved Drain Soul (2/2) - Affliction
    [51] = {1, 2, 2},  -- Improved Drain Soul 1/2
    [52] = {1, 2, 2},  -- Improved Drain Soul 2/2

    -- Level 53-54: Suppression (2/5) - Affliction
    [53] = {1, 1, 1},  -- Suppression 1/5
    [54] = {1, 1, 1},  -- Suppression 2/5

    -- Level 55: Amplify Curse (1/1) - Affliction
    [55] = {1, 3, 1},  -- Amplify Curse 1/1

    -- Level 56-58: Improved Curse of Agony (3/3) - Affliction
    [56] = {1, 4, 4},  -- Improved Curse of Agony 1/3
    [57] = {1, 4, 4},  -- Improved Curse of Agony 2/3
    [58] = {1, 4, 4},  -- Improved Curse of Agony 3/3

    -- Level 59-60: Nightfall (2/2) - Affliction
    [59] = {1, 4, 2},  -- Nightfall 1/2
    [60] = {1, 4, 2},  -- Nightfall 2/2
})
