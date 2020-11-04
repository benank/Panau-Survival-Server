AirdropConfig = 
{
    Spawn = -- Spawn settings
    {
        [AirdropType.Low] = 
        {
            min_players = 5,
            map_preview = -- Preview on discord and ingame map
            {
                time = 1, -- How many minutes it appears on the map before it drops
                size = 1000 -- How big is the radius around it
            },
            interval = 60 -- 60 minutes between airdrops of this type
        },
        [AirdropType.Mid] = 
        {
            min_players = 6,
            map_preview = 
            {
                time = 15,
                size = 1500
            },
            interval = 240 -- 4 hours between airdrops
        },
        [AirdropType.High] = 
        {
            min_players = 7,
            map_preview = 
            {
                time = 30,
                size = 3000
            },
            interval = 480 -- 8 hours between airdrops
        }
    },
    Loot = 
    {
        [AirdropType.Low] = 
        {
            ["LOCKPICK"] = 
            {
                rarity = 0.2,
                items = 
                {
                    ["Lockpick"] = {rarity = 1, min = 8, max = 15},
                }
            },
            ["AMMO"] = 
            {
                rarity = 0.3,
                items = 
                {
                    ["Revolver Ammo"] = {rarity = 0.2, min = 15, max = 30},
                    ["Handgun Ammo"] = {rarity = 0.2, min = 15, max = 30},
                    ["Sawn-Off Ammo"] = {rarity = 0.2, min = 10, max = 25},
                    ["SMG Ammo"] = {rarity = 0.2, min = 25, max = 50},
                    ["Shotgun Ammo"] = {rarity = 0.05, min = 10, max = 20},
                    ["Assault Ammo"] = {rarity = 0.05, min = 10, max = 20},
                }
            },
            ["WEAPON"] = 
            {
                rarity = 0.05,
                items = 
                {
                    ["Revolver"] = {rarity = 0.2, min_dura = 1, max_dura = 5, min = 1, max = 1},
                    ["Handgun"] = {rarity = 0.2, min_dura = 1, max_dura = 5, min = 1, max = 1},
                    ["Sawn-Off Shotgun"] = {rarity = 0.2, min_dura = 1, max_dura = 3, min = 1, max = 1},
                    ["SMG"] = {rarity = 0.2, min_dura = 1, max_dura = 4, min = 1, max = 1},
                    ["Shotgun"] = {rarity = 0.05, min_dura = 0.75, max_dura = 1, min = 1, max = 1},
                    ["Assault Rifle"] = {rarity = 0.05, min_dura = 0.75, max_dura = 1, min = 1, max = 1},
                }
            },
            ["ARMOUR"] = 
            {
                rarity = 0.1,
                items = 
                {
                    ["Helmet"] = {rarity = 0.7, min_dura = 1, max_dura = 5, min = 1, max = 1},
                    ["Police Helmet"] = {rarity = 0.3, min_dura = 1, max_dura = 3, min = 1, max = 1},
                }
            },
            ["BUILD"] = 
            {
                rarity = 0.1,
                items = 
                {
                    ["Barrel Stash"] = {rarity = 0.7, min = 1, max = 2},
                    ["Garbage Stash"] = {rarity = 0.3, min = 1, max = 2},
                }
            },
            ["EXPLOSIVE"] = 
            {
                rarity = 0.1,
                items = 
                {
                    ["Flashbang"] = {rarity = 0.2, min = 5, max = 10},
                    ["HE Grenade"] = {rarity = 0.3, min = 3, max = 10},
                    ["Toxic Grenade"] = {rarity = 0.3, min = 4, max = 10},
                    ["Mine"] = {rarity = 0.2, min = 2, max = 5},
                }
            },
            ["AIRSTRIKE"] = 
            {
                rarity = 0.1,
                items = 
                {
                    ["Cruise Missile"] = {rarity = 1, min = 2, max = 3}
                }
            },
            ["GEAR"] = 
            {
                rarity = 0.05,
                items = 
                {
                    ["Grapplehook"] = {rarity = 1, min_dura = 2, max_dura = 5, min = 1, max = 1},
                }
            },
        },
        [AirdropType.Mid] = 
        {
            ["LOCKPICK"] = 
            {
                rarity = 1,
                items = 
                {
                    ["Lockpick"] = {rarity = 1, min = 15, max = 30},
                }
            },
            -- TODO
        },
        [AirdropType.High] = 
        {
            ["LOCKPICK"] = 
            {
                rarity = 1,
                items = 
                {
                    ["Lockpick"] = {rarity = 1, min = 30, max = 50},
                }
            },
            -- TODO
        }
    }
}