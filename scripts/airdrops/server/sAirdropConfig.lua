AirdropConfig = 
{
    RemoveTime = 1000 * 60 * 30, -- After the first box has been opened, it will be removed in 30 minutes
    Messages = 
    {
        Incoming = 
            "--------------------------------------------------------------\n\n" ..
            "**LEVEL %d AIRDROP INCOMING IN %d MINUTES**\n\n" ..
            "*Join the server to see approximate map location.*\n\n" ..
            "--------------------------------------------------------------",
        Delivered = 
            "--------------------------------------------------------------\n\n" ..
            "**LEVEL %d AIRDROP HAS BEEN DELIVERED!**\n\n" ..
            "*Join the server to see approximate map location.*\n\n" ..
            "--------------------------------------------------------------"
    },
    Spawn = -- Spawn settings
    {
        [AirdropType.Low] = 
        {
            min_players = 2,
            health = 5,
            drones = 
            {
                amount = {min = 1, max = 3},
                level = {min = 3, max = 10}
            },
            map_preview = -- Preview on discord and ingame map
            {
                time = 10, -- How many minutes it appears on the map before it drops
                size = 750 -- How big is the radius around it
            },
            chance = 0.2, -- Chance of the airdrop spawning every interval if the conditions are met
            interval = 30 -- 0.5 hours between airdrops of this type
        },
        [AirdropType.Mid] = 
        {
            min_players = 4,
            health = 2,
            drones = 
            {
                amount = {min = 3, max = 7},
                level = {min = 10, max = 25}
            },
            map_preview = 
            {
                time = 20,
                size = 1500
            },
            chance = 0.3,
            interval = 60 -- 1 hour between airdrops
        },
        [AirdropType.High] = 
        {
            min_players = 7,
            health = 4,
            drones = 
            {
                amount = {min = 3, max = 6},
                level = {min = 20, max = 50}
            },
            map_preview = 
            {
                time = 30,
                size = 3000
            },
            chance = 0.5,
            interval = 120 -- 2 hours between airdrops
        }
    },

}