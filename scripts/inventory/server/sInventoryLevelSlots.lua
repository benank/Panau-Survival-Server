-- Slot bonuses based on level
local slot_amounts = 
{
    ["Survival"] = {
        [0] = 1
    },
    ["Supplies"] = {
        [0] = 1
    },
    ["Explosives"] = {
        [0] = 1
    },
    ["Weapons"] = {
        [0] = 1
    }
}



function GetNumSlotsInCategory(category, level)
    if not slot_amounts[category] then
        print(string.format("Category %s not found in GetNumSlotsInCategory", category))
        return 0
    end

    -- Find the maximum level of bonuses that they can get at their current level
    local max_level = 0
    for min_level, slot_bonus in pairs(slot_amounts[category]) do
        if min_level >= max_level and level <= min_level then
            max_level = min_level
        end
    end

    return slot_amounts[category][max_level]
end