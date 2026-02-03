--[[
Guidelime Vanilla - Talent Templates

Paladin talent templates for leveling

Tree Index:
1 = Holy
2 = Protection
3 = Retribution

Format: [level] = {tree, row, col}
Row 1 requires 0 points in tree, Row 2 requires 5 points, Row 3 requires 10, etc.
]]--

local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end

-- Retribution Leveling Build (TurtleWoW)
-- Source: https://talents.turtlecraft.gg/paladin?points=FAAoB-FAY-AoAoFKYAFAFABY
GLV:RegisterTalentTemplate("PALADIN", "Retribution", "leveling", {
    [10] = {1, 1, 2},   -- Divine Strength 1/5
    [11] = {1, 1, 2},   -- Divine Strength 2/5
    [12] = {1, 1, 2},   -- Divine Strength 3/5
    [13] = {1, 1, 2},   -- Divine Strength 4/5
    [14] = {1, 1, 2},   -- Divine Strength 5/5

    [15] = {3, 1, 3},   -- Benediction 1/5
    [16] = {3, 1, 3},   -- Benediction 2/5
    [17] = {3, 1, 3},   -- Benediction 3/5
    [18] = {3, 1, 3},   -- Benediction 4/5
    [19] = {3, 1, 3},   -- Benediction 5/5

    [20] = {1, 2, 3},   -- Improved Seal 1/5
    [21] = {1, 2, 3},   -- Improved Seal 2/5
    [22] = {1, 2, 3},   -- Improved Seal 3/5
    [23] = {1, 2, 3},   -- Improved Seal 4/5
    [24] = {1, 2, 3},   -- Improved Seal 5/5

    [25] = {3, 2, 3},   -- Deflection 1/5
    [26] = {3, 2, 3},   -- Deflection 2/5
    [27] = {3, 2, 3},   -- Deflection 3/5
    [28] = {3, 2, 3},   -- Deflection 4/5
    [29] = {3, 2, 3},   -- Deflection 5/5
    
    [30] = {3, 3, 2},   -- Conviction 1/5
    [31] = {3, 3, 2},   -- Conviction 2/5
    [32] = {3, 3, 2},   -- Conviction 3/5
    [33] = {3, 3, 2},   -- Conviction 4/5
    [34] = {3, 3, 2},   -- Conviction 5/5

    [35] = {3, 4, 1},   -- Two-Handed Spec 1/3
    [36] = {3, 4, 1},   -- Two-Handed Spec 2/3
    [37] = {3, 4, 1},   -- Two-Handed Spec 3/3

    [38] = {2, 1, 2},   -- Improved Devotion Aura 1/5
    [39] = {2, 1, 2},   -- Improved Devotion Aura 2/5
    [40] = {2, 1, 2},   -- Improved Devotion Aura 3/5
    [41] = {2, 1, 2},   -- Improved Devotion Aura 4/5
    [42] = {2, 1, 2},   -- Improved Devotion Aura 5/5

    [43] = {2, 2, 1},   -- Precision 1/3
    [44] = {2, 2, 1},   -- Precision 2/3
    [45] = {2, 2, 1},   -- Precision 3/3    

    [46] = {3, 3, 4},   -- Pursuit of Justice 1/2
    [47] = {3, 3, 4},   -- Pursuit of Justice 2/2
    
    [48] = {3, 3, 3},   -- Blessing of Kings 1/1
    
    [49] = {3, 5, 2},   -- Vengeance 1/5
    [50] = {3, 5, 2},   -- Vengeance 2/5
    [51] = {3, 5, 2},   -- Vengeance 3/5
    [52] = {3, 5, 2},   -- Vengeance 4/5
    [53] = {3, 5, 2},   -- Vengeance 5/5

    [54] = {3, 6, 2},   -- Vengeful Strikes 1/5
    [55] = {3, 6, 2},   -- Vengeful Strikes 2/5
    [56] = {3, 6, 2},   -- Vengeful Strikes 3/5
    [57] = {3, 6, 2},   -- Vengeful Strikes 4/5
    [58] = {3, 6, 2},   -- Vengeful Strikes 5/5

    [59] = {3, 7, 2},   -- Repentance 1/1

    [60] = {1, 3, 2},   -- Sanctity Aura 1/1

})
