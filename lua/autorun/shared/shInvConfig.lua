Inventory = {}

Inventory.config = 
{
    categories = 
    {
        [1] = {name = "Weapons", slots = 4},
        [2] = {name = "Explosives", slots = 6},
        [3] = {name = "Supplies", slots = 6},
        [4] = {name = "Survival", slots = 8}
    },
    max_slots_per_category = 20,
    uid = 0,
    default_inv = 
    {
        {
            name = "Can of Peaches",
            amount = 3
        },
        {
            name = "Water",
            amount = 3
        },
        {
            name = "Shotgun",
            amount = 1
        },
        {
            name = "Shotgun Ammo",
            amount = 25
        },
        {
            name = "Handgun",
            amount = 1
        },
        {
            name = "Parachute",
            amount = 1
        },
        {
            name = "Lockpick",
            amount = 10
        },
        {
            name = "Grapplehook",
            amount = 1
        },
        
    },
    max_grapple_upgrades = 4
}

function GetInventoryNumSlots()

    local slots = 0

    for k,v in pairs(Inventory.config.categories) do
        slots = slots + v.slots
    end

    return slots

end

function CategoryExists(cat)

    for k,v in pairs(Inventory.config.categories) do
        if v.name == cat then return true end
    end

    return false

end

-- Gets a new unique id for an item or stack
function GetUID()
    Inventory.config.uid = Inventory.config.uid + 1
    return Inventory.config.uid
end