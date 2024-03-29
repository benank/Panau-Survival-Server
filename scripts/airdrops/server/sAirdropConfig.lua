AirdropConfig = 
{
    RemoveTime = 1000 * 60 * 60, -- After the first box has been opened, it will be removed in 60 minutes
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
            min_players = 1,
            health = 2,
            drones = 
            {
                amount = {min = 3, max = 8},
                level = {min = 15, max = 30}
            },
            map_preview = -- Preview on discord and ingame map
            {
                time = 10, -- How many minutes it appears on the map before it drops
                size = 500 -- How big is the radius around it
            },
            chance = 0.03, -- Chance of the airdrop spawning every interval if the conditions are met
            interval = 30 -- 30m between airdrops of this type
        },
        [AirdropType.Mid] = 
        {
            min_players = 3,
            health = 4,
            drones = 
            {
                amount = {min = 4, max = 10},
                level = {min = 30, max = 70}
            },
            map_preview = 
            {
                time = 15,
                size = 1000
            },
            chance = 0.3,
            interval = 60 -- 1 hours between airdrops
        },
        [AirdropType.High] = 
        {
            min_players = 5,
            health = 6,
            drones = 
            {
                amount = {min = 5, max = 12},
                level = {min = 80, max = 200}
            },
            map_preview = 
            {
                time = 25,
                size = 2000
            },
            chance = 0.7,
            interval = 120 -- 2 hours between airdrops
        }
    },

}