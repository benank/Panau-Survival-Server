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
            min_players = 5,
            health = 5,
            map_preview = -- Preview on discord and ingame map
            {
                time = 15, -- How many minutes it appears on the map before it drops
                size = 750 -- How big is the radius around it
            },
            chance = 0.04, -- Chance of the airdrop spawning every interval if the conditions are met
            interval = 240 -- 4 hours between airdrops of this type
        },
        [AirdropType.Mid] = 
        {
            min_players = 7,
            health = 2,
            map_preview = 
            {
                time = 30,
                size = 1500
            },
            chance = 0.05,
            interval = 480 -- 8 hours between airdrops
        },
        [AirdropType.High] = 
        {
            min_players = 10,
            health = 4,
            map_preview = 
            {
                time = 60,
                size = 3000
            },
            chance = 0.02,
            interval = 1440 -- 24 hours between airdrops
        }
    },

}