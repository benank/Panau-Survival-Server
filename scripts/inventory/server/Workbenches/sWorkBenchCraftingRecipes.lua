WorkbenchCraftingRecpies = 
{
    {
        craft_time = 1200,
        result_item = {
            name = "Teleporter",
            durability = 100 -- Absolute durability
        },
        recipe = {
            {
                name = "Teleporter Hull",
                amount = 1 -- Relative durabilities
            },
            {
                name = "Lock-On Module",
                amount = 2,
                min_durability = 5
            },
            {
                name = "Warp Core",
                amount = 5
            }
        }
    },
    {
        craft_time = 180,
        result_item = {
            name = "Teleporter Repair Tool"
        },
        recipe = {
            {
                name = "Vehicle Repair",
                amount = 5
            },
            {
                name = "Lock-On Module",
                amount = 1,
                min_durability = 5
            },
            {
                name = "Warp Core",
                amount = 1
            }
        }
    }
}