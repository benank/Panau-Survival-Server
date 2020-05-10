-- Slot bonuses based on level
local slot_amounts = 
{
    ["Survival"] = {
        [0] = 0,
        [12] = 1,
        [24] = 2,
        [36] = 3,
        [48] = 4,
        [54] = 5,
        [60] = 6
    },
    ["Supplies"] = {
        [0] = 0,
        [9] = 1,
        [21] = 2,
        [33] = 3,
        [45] = 4,
        [51] = 5,
        [57] = 6
    },
    ["Explosives"] = {
        [0] = 0,
        [6] = 1,
        [18] = 2,
        [30] = 3,
        [42] = 4
    },
    ["Weapons"] = {
        [0] = 0,
        [3] = 1,
        [15] = 2,
        [27] = 3,
        [39] = 4
    }
}

function GetNumSlotsInCategoryFromLevel(category, level)
    if not slot_amounts[category] then
        print(string.format("Category %s not found in GetNumSlotsInCategory", category))
        return 0
    end

    return GetMaxFromLevel(level, slot_amounts[category])
end

-- Amount of slots dropped on death per level
local drop_slot_amounts = 
{
    [0] = 0,
    [1] = 1,
    [2] = 2,
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
    [48] = 19,
    [51] = 20,
    [54] = 21,
    [57] = 22,
    [60] = 23
}

function GetNumSlotsDroppedOnDeath(level)
    return GetMaxFromLevel(level, drop_slot_amounts)
end