-- Slot bonuses based on level
local slot_amounts = 
{
    ["Survival"] = {
        [46] = 1,
        [91] = 1,
        [135] = 1,
        [164] = 1,
    },
    ["Supplies"] = {
        [31] = 1,
        [86] = 1,
        [128] = 1,
        [158] = 1,
    },
    ["Explosives"] = {
        [20] = 1,
        [72] = 1,
        [119] = 1,
        [151] = 1,
    },
    ["Weapons"] = {
        [4] = 1,
        [62] = 1,
        [107] = 1,
        [141] = 1,
    }
}

function GetNumSlotsInCategoryFromPerks(category, perks)
    if not slot_amounts[category] then
        print(string.format("Category %s not found in GetNumSlotsInCategory", category))
        return 0
    end

    local amount = 0

    for id, perk in pairs(perks) do
        if slot_amounts[category][id] then
            amount = amount + slot_amounts[category][id]
        end
    end

    return amount
end

-- Amount of slots dropped on death per level
local drop_slot_amounts = 
{
    [0] = 1,
    [1] = 2,
    [2] = 3,
    [3] = 3,
    [4] = 4,
    [6] = 5,
    [9] = 6,
    [12] = 7,
    [15] = 8,
    [18] = 9,
    [21] = 10,
    [24] = 11,
    [27] = 12,
    [30] = 13,
    [33] = 14,
    [36] = 15,
    [39] = 16,
    [42] = 17,
    [45] = 18,
    [48] = 19
}

function GetNumSlotsDroppedOnDeath(level)
    return GetMaxFromLevel(level, drop_slot_amounts)
end