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
            min_players = 4,
            health = 5,
            map_preview = -- Preview on discord and ingame map
            {
                time = 15, -- How many minutes it appears on the map before it drops
                size = 750 -- How big is the radius around it
            },
            chance = 0.1, -- Chance of the airdrop spawning every interval if the conditions are met
            interval = 90 -- 1.5 hours between airdrops of this type
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
            chance = 0.15,
            interval = 180 -- 3 hours between airdrops
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
            chance = 0.2,
            interval = 360 -- 6 hours between airdrops
        }
    },

}