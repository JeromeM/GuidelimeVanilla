--[[
Guidelime Vanilla - Talent Templates

Rogue talent templates for leveling
Source: Icy Veins WoW Classic

Tree Index:
1 = Assassination
2 = Combat
3 = Subtlety

Format: [level] = {tree, row, col}
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Combat Swords Leveling Build (recommended by Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/sword-rogue-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("ROGUE", "Combat Swords (Icy Veins)", "leveling", {
    -- Level 10-11: Improved Sinister Strike (2/2) - Combat
    [10] = {2, 1, 1},  -- Improved Sinister Strike 1/2
    [11] = {2, 1, 1},  -- Improved Sinister Strike 2/2

    -- Level 12-14: Improved Gouge (3/3) - Combat
    [12] = {2, 1, 3},  -- Improved Gouge 1/3
    [13] = {2, 1, 3},  -- Improved Gouge 2/3
    [14] = {2, 1, 3},  -- Improved Gouge 3/3

    -- Level 15-19: Deflection (5/5) - Combat
    [15] = {2, 2, 1},  -- Deflection 1/5
    [16] = {2, 2, 1},  -- Deflection 2/5
    [17] = {2, 2, 1},  -- Deflection 3/5
    [18] = {2, 2, 1},  -- Deflection 4/5
    [19] = {2, 2, 1},  -- Deflection 5/5

    -- Level 20: Riposte (1/1) - Combat
    [20] = {2, 3, 1},  -- Riposte 1/1

    -- Level 21-22: Endurance (2/2) - Combat
    [21] = {2, 3, 3},  -- Endurance 1/2
    [22] = {2, 3, 3},  -- Endurance 2/2

    -- Level 23-24: Improved Sprint (2/2) - Combat
    [23] = {2, 3, 4},  -- Improved Sprint 1/2
    [24] = {2, 3, 4},  -- Improved Sprint 2/2

    -- Level 25-29: Precision (5/5) - Combat
    [25] = {2, 2, 3},  -- Precision 1/5
    [26] = {2, 2, 3},  -- Precision 2/5
    [27] = {2, 2, 3},  -- Precision 3/5
    [28] = {2, 2, 3},  -- Precision 4/5
    [29] = {2, 2, 3},  -- Precision 5/5

    -- Level 30: Blade Flurry (1/1) - Combat
    [30] = {2, 5, 1},  -- Blade Flurry 1/1

    -- Level 31-35: Dual Wield Specialization (5/5) - Combat
    [31] = {2, 4, 2},  -- Dual Wield Specialization 1/5
    [32] = {2, 4, 2},  -- Dual Wield Specialization 2/5
    [33] = {2, 4, 2},  -- Dual Wield Specialization 3/5
    [34] = {2, 4, 2},  -- Dual Wield Specialization 4/5
    [35] = {2, 4, 2},  -- Dual Wield Specialization 5/5

    -- Level 36-38: Aggression (3/3) - Combat
    [36] = {2, 6, 3},  -- Aggression 1/3
    [37] = {2, 6, 3},  -- Aggression 2/3
    [38] = {2, 6, 3},  -- Aggression 3/3

    -- Level 39-40: Weapon Expertise (2/2) - Combat
    [39] = {2, 5, 3},  -- Weapon Expertise 1/2
    [40] = {2, 5, 3},  -- Weapon Expertise 2/2

    -- Level 41: Adrenaline Rush (1/1) - Combat
    [41] = {2, 7, 2},  -- Adrenaline Rush 1/1

    -- Level 42-46: Malice (5/5) - Assassination
    [42] = {1, 1, 3},  -- Malice 1/5
    [43] = {1, 1, 3},  -- Malice 2/5
    [44] = {1, 1, 3},  -- Malice 3/5
    [45] = {1, 1, 3},  -- Malice 4/5
    [46] = {1, 1, 3},  -- Malice 5/5

    -- Level 47-49: Improved Slice and Dice (3/3) - Assassination
    [47] = {1, 2, 4},  -- Improved Slice and Dice 1/3
    [48] = {1, 2, 4},  -- Improved Slice and Dice 2/3
    [49] = {1, 2, 4},  -- Improved Slice and Dice 3/3

    -- Level 50-51: Murder (2/2) - Assassination
    [50] = {1, 3, 1},  -- Murder 1/2
    [51] = {1, 3, 1},  -- Murder 2/2

    -- Level 52: Relentless Strikes (1/1) - Assassination
    [52] = {1, 5, 1},  -- Relentless Strikes 1/1

    -- Level 53-57: Lethality (5/5) - Assassination
    [53] = {1, 3, 3},  -- Lethality 1/5
    [54] = {1, 3, 3},  -- Lethality 2/5
    [55] = {1, 3, 3},  -- Lethality 3/5
    [56] = {1, 3, 3},  -- Lethality 4/5
    [57] = {1, 3, 3},  -- Lethality 5/5

    -- Level 58-60: Ruthlessness (3/3) - Assassination
    [58] = {1, 2, 1},  -- Ruthlessness 1/3
    [59] = {1, 2, 1},  -- Ruthlessness 2/3
    [60] = {1, 2, 1},  -- Ruthlessness 3/3
})

-- Combat Daggers Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/dagger-rogue-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("ROGUE", "Combat Daggers (Icy Veins)", "leveling", {
    -- Level 10-11: Remorseless Attacks (2/2) - Assassination
    [10] = {1, 1, 1},  -- Remorseless Attacks 1/2
    [11] = {1, 1, 1},  -- Remorseless Attacks 2/2

    -- Level 12-16: Opportunity (5/5) - Assassination
    [12] = {1, 3, 4},  -- Opportunity 1/5
    [13] = {1, 3, 4},  -- Opportunity 2/5
    [14] = {1, 3, 4},  -- Opportunity 3/5
    [15] = {1, 3, 4},  -- Opportunity 4/5
    [16] = {1, 3, 4},  -- Opportunity 5/5

    -- Level 17-19: Improved Gouge (3/3) - Combat
    [17] = {2, 1, 3},  -- Improved Gouge 1/3
    [18] = {2, 1, 3},  -- Improved Gouge 2/3
    [19] = {2, 1, 3},  -- Improved Gouge 3/3

    -- Level 20-21: Improved Sinister Strike (2/2) - Combat
    [20] = {2, 1, 1},  -- Improved Sinister Strike 1/2
    [21] = {2, 1, 1},  -- Improved Sinister Strike 2/2

    -- Level 22-24: Improved Backstab (3/3) - Combat
    [22] = {2, 3, 2},  -- Improved Backstab 1/3
    [23] = {2, 3, 2},  -- Improved Backstab 2/3
    [24] = {2, 3, 2},  -- Improved Backstab 3/3

    -- Level 25-29: Precision (5/5) - Combat
    [25] = {2, 2, 3},  -- Precision 1/5
    [26] = {2, 2, 3},  -- Precision 2/5
    [27] = {2, 2, 3},  -- Precision 3/5
    [28] = {2, 2, 3},  -- Precision 4/5
    [29] = {2, 2, 3},  -- Precision 5/5

    -- Level 30-31: Improved Sprint (2/2) - Combat
    [30] = {2, 3, 4},  -- Improved Sprint 1/2
    [31] = {2, 3, 4},  -- Improved Sprint 2/2

    -- Level 32-33: Endurance (2/2) - Combat
    [32] = {2, 3, 3},  -- Endurance 1/2
    [33] = {2, 3, 3},  -- Endurance 2/2

    -- Level 34-38: Dagger Specialization (5/5) - Combat
    [34] = {2, 4, 3},  -- Dagger Specialization 1/5
    [35] = {2, 4, 3},  -- Dagger Specialization 2/5
    [36] = {2, 4, 3},  -- Dagger Specialization 3/5
    [37] = {2, 4, 3},  -- Dagger Specialization 4/5
    [38] = {2, 4, 3},  -- Dagger Specialization 5/5

    -- Level 39: Blade Flurry (1/1) - Combat
    [39] = {2, 5, 1},  -- Blade Flurry 1/1

    -- Level 40-44: Dual Wield Specialization (5/5) - Combat
    [40] = {2, 4, 2},  -- Dual Wield Specialization 1/5
    [41] = {2, 4, 2},  -- Dual Wield Specialization 2/5
    [42] = {2, 4, 2},  -- Dual Wield Specialization 3/5
    [43] = {2, 4, 2},  -- Dual Wield Specialization 4/5
    [44] = {2, 4, 2},  -- Dual Wield Specialization 5/5

    -- Level 45-46: Weapon Expertise (2/2) - Combat
    [45] = {2, 5, 3},  -- Weapon Expertise 1/2
    [46] = {2, 5, 3},  -- Weapon Expertise 2/2

    -- Level 47: Adrenaline Rush (1/1) - Combat
    [47] = {2, 7, 2},  -- Adrenaline Rush 1/1

    -- Level 48-52: Malice (5/5) - Assassination
    [48] = {1, 1, 3},  -- Malice 1/5
    [49] = {1, 1, 3},  -- Malice 2/5
    [50] = {1, 1, 3},  -- Malice 3/5
    [51] = {1, 1, 3},  -- Malice 4/5
    [52] = {1, 1, 3},  -- Malice 5/5

    -- Level 53-55: Ruthlessness (3/3) - Assassination
    [53] = {1, 2, 1},  -- Ruthlessness 1/3
    [54] = {1, 2, 1},  -- Ruthlessness 2/3
    [55] = {1, 2, 1},  -- Ruthlessness 3/3

    -- Level 56: Relentless Strikes (1/1) - Assassination
    [56] = {1, 5, 1},  -- Relentless Strikes 1/1

    -- Level 57-60: Lethality (4/5) - Assassination
    [57] = {1, 3, 3},  -- Lethality 1/5
    [58] = {1, 3, 3},  -- Lethality 2/5
    [59] = {1, 3, 3},  -- Lethality 3/5
    [60] = {1, 3, 3},  -- Lethality 4/5
})

-- Subtlety Leveling Build (Icy Veins)
-- Source: https://www.icy-veins.com/wow-classic/subtlety-rogue-leveling-talent-build-from-1-to-60
GLV:RegisterTalentTemplate("ROGUE", "Subtlety (Icy Veins)", "leveling", {
    -- Level 10-14: Opportunity (5/5) - Subtlety
    [10] = {3, 1, 3},  -- Opportunity 1/5
    [11] = {3, 1, 3},  -- Opportunity 2/5
    [12] = {3, 1, 3},  -- Opportunity 3/5
    [13] = {3, 1, 3},  -- Opportunity 4/5
    [14] = {3, 1, 3},  -- Opportunity 5/5

    -- Level 15-19: Camouflage (5/5) - Subtlety
    [15] = {3, 2, 1},  -- Camouflage 1/5
    [16] = {3, 2, 1},  -- Camouflage 2/5
    [17] = {3, 2, 1},  -- Camouflage 3/5
    [18] = {3, 2, 1},  -- Camouflage 4/5
    [19] = {3, 2, 1},  -- Camouflage 5/5

    -- Level 20: Ghostly Strike (1/1) - Subtlety
    [20] = {3, 3, 2},  -- Ghostly Strike 1/1

    -- Level 21-23: Improved Ambush (3/3) - Subtlety
    [21] = {3, 2, 4},  -- Improved Ambush 1/3
    [22] = {3, 2, 4},  -- Improved Ambush 2/3
    [23] = {3, 2, 4},  -- Improved Ambush 3/3

    -- Level 24: Elusiveness (1/2) - Subtlety
    [24] = {3, 4, 3},  -- Elusiveness 1/2

    -- Level 25-27: Serrated Blades (3/3) - Subtlety
    [25] = {3, 3, 3},  -- Serrated Blades 1/3
    [26] = {3, 3, 3},  -- Serrated Blades 2/3
    [27] = {3, 3, 3},  -- Serrated Blades 3/3

    -- Level 28-30: Improved Sap (3/3) - Subtlety
    [28] = {3, 3, 1},  -- Improved Sap 1/3
    [29] = {3, 3, 1},  -- Improved Sap 2/3
    [30] = {3, 3, 1},  -- Improved Sap 3/3

    -- Level 31: Hemorrhage (1/1) - Subtlety
    [31] = {3, 5, 2},  -- Hemorrhage 1/1

    -- Level 32: Preparation (1/1) - Subtlety
    [32] = {3, 5, 1},  -- Preparation 1/1

    -- Level 33-34: Heightened Senses (2/2) - Subtlety
    [33] = {3, 5, 4},  -- Heightened Senses 1/2
    [34] = {3, 5, 4},  -- Heightened Senses 2/2

    -- Level 35-39: Deadliness (5/5) - Subtlety
    [35] = {3, 6, 3},  -- Deadliness 1/5
    [36] = {3, 6, 3},  -- Deadliness 2/5
    [37] = {3, 6, 3},  -- Deadliness 3/5
    [38] = {3, 6, 3},  -- Deadliness 4/5
    [39] = {3, 6, 3},  -- Deadliness 5/5

    -- Level 40-41: Remorseless Attacks (2/2) - Assassination
    [40] = {1, 1, 1},  -- Remorseless Attacks 1/2
    [41] = {1, 1, 1},  -- Remorseless Attacks 2/2

    -- Level 42-46: Malice (5/5) - Assassination
    [42] = {1, 1, 3},  -- Malice 1/5
    [43] = {1, 1, 3},  -- Malice 2/5
    [44] = {1, 1, 3},  -- Malice 3/5
    [45] = {1, 1, 3},  -- Malice 4/5
    [46] = {1, 1, 3},  -- Malice 5/5

    -- Level 47-49: Murder (2/2) + Improved Eviscerate (1/3) - Assassination
    [47] = {1, 3, 1},  -- Murder 1/2
    [48] = {1, 3, 1},  -- Murder 2/2
    [49] = {1, 1, 2},  -- Improved Eviscerate 1/3

    -- Level 50: Relentless Strikes (1/1) - Assassination
    [50] = {1, 5, 1},  -- Relentless Strikes 1/1

    -- Level 51-52: Improved Eviscerate (3/3) - Assassination
    [51] = {1, 1, 2},  -- Improved Eviscerate 2/3
    [52] = {1, 1, 2},  -- Improved Eviscerate 3/3

    -- Level 53-57: Lethality (5/5) - Assassination
    [53] = {1, 3, 3},  -- Lethality 1/5
    [54] = {1, 3, 3},  -- Lethality 2/5
    [55] = {1, 3, 3},  -- Lethality 3/5
    [56] = {1, 3, 3},  -- Lethality 4/5
    [57] = {1, 3, 3},  -- Lethality 5/5

    -- Level 58-59: Vile Poisons (2/5) - Assassination
    [58] = {1, 4, 3},  -- Vile Poisons 1/5
    [59] = {1, 4, 3},  -- Vile Poisons 2/5

    -- Level 60: Cold Blood (1/1) - Assassination
    [60] = {1, 5, 2},  -- Cold Blood 1/1
})
