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
                name = "Phone Booth",
                amount = 1, -- Relative durabilities
                min_durability = 5
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
            name = "Teleporter Upgrade"
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
    },
    {
        craft_time = 300,
        result_item = {
            name = "Teleporter",
            add_dura = {from = "Teleporter", amount = 100}
        },
        recipe = {
            {
                name = "Teleporter",
                amount = 1
            },
            {
                name = "Teleporter Upgrade",
                amount = 1
            }
        }
    }
}