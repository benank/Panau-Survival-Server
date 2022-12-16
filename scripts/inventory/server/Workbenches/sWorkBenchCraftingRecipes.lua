WorkbenchCraftingRecpies = 
{
    {
        craft_time = 1200,
        result_item = {
            name = "Teleporter",
            durability = 100 -- Absolute durability
        },
        announce = 
            "--------------------------------------------------------------\n\n" ..
            "**Player %s started crafting a __%s__ at the %s!**\n\n" ..
            "Crafting will complete in **%s** minutes.\n\n" ..
            "*Join the server to interrupt the process and steal it for your own.*\n\n" ..
            "--------------------------------------------------------------",
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
    },
    {
        craft_time = 300,
        announce = 
            "--------------------------------------------------------------\n\n" ..
            "**Player %s started crafting a __%s__ at the %s!**\n\n" ..
            "Crafting will complete in **%s** minutes.\n\n" ..
            "*Join the server to interrupt the process and steal it for your own.*\n\n" ..
            "--------------------------------------------------------------",
        result_item = {
            name = "Drone",
            custom_data = function(custom_data, items)
                for _, item_stack in pairs(items) do
                    if item_stack:GetProperty("name") == "Drone AI" then
                        custom_data.level = item_stack.contents[1].custom_data.level
                        break
                    end
                end
                return custom_data
            end
        },
        recipe = {
            {
                name = "Drone Body",
                amount = 1
            },
            {
                name = "Drone AI",
                amount = 1
            },
            {
                name = "Drone Weapons",
                amount = 1
            }
        }
    },
    {
        craft_time = 15,
        result_item = {
            name = "Hot Chocolate"
        },
        recipe = {
            {
                name = "Chocolate",
                amount = 3
            },
            {
                name = "Milk",
                amount = 1
            }
        }
    },
    {
        craft_time = 60,
        result_item = {
            name = "Drone Body"
        },
        recipe = {
            {
                name = "Battery",
                amount = 3,
                min_durability = 5
            },
            {
                name = "Wall",
                amount = 5,
                min_durability = 5
            },
            {
                name = "Nitro",
                amount = 1,
                min_durability = 5
            }
        }
    },
    {
        craft_time = 60,
        result_item = {
            name = "Drone Weapons"
        },
        recipe = {
            {
                name = "Machine Gun",
                amount = 1,
                min_durability = 1
            },
            {
                name = "Machine Gun",
                amount = 1,
                min_durability = 1
            },
            {
                name = "Machine Gun Ammo",
                amount = 100
            }
        }
    },
    {
        craft_time = 60,
        result_item = {
            name = "Drone AI",
            custom_data = function(custom_data, items)
                for _, item_stack in pairs(items) do
                    if item_stack:GetProperty("name") == "Drone Chip" then
                        custom_data.level = item_stack.contents[1].custom_data.level
                        break
                    end
                end
                return custom_data
            end
        },
        recipe = {
            {
                name = "Lock-On Module",
                amount = 1,
                min_durability = 2.5
            },
            {
                name = "Drone Chip",
                amount = 1
            },
            {
                name = "Ping",
                amount = 10
            }
        }
    }
}