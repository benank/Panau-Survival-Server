Inventory = {}

Inventory.config = 
{
    categories = 
    {
        [1] = {name = "General", slots = 24},
        [2] = {name = "Consumables", slots = 16},
        [3] = {name = "Build", slots = 24},
        [4] = {name = "Weapons", slots = 20},
        [5] = {name = "Ammo", slots = 16},
        [6] = {name = "Clothing", slots = 16}
    },
    uid = 0,
    icons = 
    {
        "item_None",
        "item_Unknown",
        "item_Apple",
        "item_Water Bottle",
        "item_Assault Ammo",
        "item_Grapplehook Upgrade - Recharge",
        "item_Grapplehook Upgrade - Range",
        "item_Grapplehook Upgrade - Speed",
        "item_Grapplehook Upgrade - Gun",
        "item_Grapplehook Upgrade - Underwater",
        "item_Grapplehook Upgrade - Impulse",
        "item_Grapplehook Upgrade - Smart",
        "item_Grenade Munitions",
        "item_Machine Gun Ammo",
        "item_Medkit",
        "item_Medpack",
        "item_Parachute",
        "item_Pistol Ammo",
        "item_Radiation Pills",
        "item_Revolver Ammo",
        "item_Rockets",
        "item_Sawn-Off Ammo",
        "item_Shotgun Ammo",
        "item_Sniper Ammo",
        "item_Submachine Gun Ammo",
        "item_Credits",
        "item_Grid Armor MKI",
        "item_Grid Armor MKII",
        "item_Grid Armor MKIII",
        "item_Grid Armor MKIV",
        "item_Red Spray Paint",
        "item_Orange Spray Paint",
        "item_Yellow Spray Paint",
        "item_Green Spray Paint",
        "item_Blue Spray Paint",
        "item_Purple Spray Paint",
        "item_Pink Spray Paint",
        "item_White Spray Paint",
        "item_Black Spray Paint",
        "item_Spray Paint Remover",
        "item_Woet",
        "item_Nitro",
        "item_CamelBak",
        "item_Scrap Metal",
        "item_Rations",
        "item_Trail Mix",
        "item_Soda",
        "item_Granola Bar",
        "item_Rocket Launcher",
        "item_C4",
        "item_Grenade Launcher",
        "item_Machine Gun",
        "item_Pistol",
        "item_Revolver",
        "item_Sawn-Off Shotgun",
        "item_Shotgun",
        "item_Sniper",
        "item_Submachine Gun",
        "item_Assault Rifle",
        "item_Batteries",
        "item_Car Paint",
        "item_Bubbles",
        "item_Bubble Gun",
        "item_Call Air Support",
        "item_Vehicle Repair Kit",
        "item_Binoculars",
        "item_Stun Grenade",
        "item_Impulse Grenade",
        "item_Concussion Grenade",
        "item_Smoke Grenade",
        "item_Toxic Grenade",
        "item_EMP Grenade",
        "item_Warp Grenade",
        "item_Anti-Tank Grenade",
        "item_Incendiary Grenade",
        "item_Fragmentation Grenade",
        "item_Portal Gun",
        "item_Death Drop Locator",
        "item_EMP",
        "item_Wingsuit",
    },
    default_inv = 
    {
        {
            name = "Apple",
            amount = 3
        },
        {
            name = "Water Bottle",
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
            name = "Radiation Pills",
            amount = 3
        },
        {
            name = "Revolver",
            amount = 1
        },
        {
            name = "Parachute",
            amount = 1
        },
        {
            name = "Credits",
            amount = 10
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