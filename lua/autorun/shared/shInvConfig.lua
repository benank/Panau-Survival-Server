Inventory = {}

Inventory.config = 
{
    categories = 
    {
        [1] = {name = "Weapons", slots = 2},
        [2] = {name = "Explosives", slots = 3},
        [3] = {name = "Supplies", slots = 7},
        [4] = {name = "Survival", slots = 6}
    },
    max_slots_per_category = 20,
    uid = 0,
    default_inv = 
    {
        {
            name = "Can of Beans",
            amount = 15
        },
        {
            name = "Lockpick",
            amount = 3
        },
        {
            name = "Handgun",
            amount = 1,
            durability = 0.75
        },
        {
            name = "Handgun Ammo",
            amount = 100
        },
        {
            name = "HE Grenade",
            amount = 10
        },
        {
            name = "Parachute",
            amount = 1,
            durability = 0.1
        },
        {
            name = "Grapplehook",
            amount = 1,
            durability = 0.5
        },
        {
            name = "Helmet",
            amount = 1,
            durability = 0.75
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "Wall",
            amount = 1
        },
        {
            name = "LandClaim",
            amount = 1,
            custom_data = {
                size = 20
            }
        }
    },
    default_respawn_inv = 
    {
        {
            name = "Grapplehook",
            amount = 1,
            durability = 0.15
        },
        {
            name = "Handgun",
            amount = 1,
            durability = 0.5
        },
        {
            name = "Handgun Ammo",
            amount = 50
        },
        {
            name = "Can of Beans",
            amount = 3
        },
        {
            name = "Bandages",
            amount = 5
        },
        {
            name = "Helmet",
            amount = 1,
            durability = 0.5
        }
    }
}

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