AirdropConfig = 
{
    Messages = 
    {
        Incoming = 
            "----------------------------------------\n\n" ..
            "**LEVEL %d AIRDROP INCOMING IN %d MINUTES**\n\n" ..
            "*Join the server to see approximate map location.*\n\n" ..
            "----------------------------------------",
        Delivered = 
            "----------------------------------------\n\n" ..
            "**LEVEL %d AIRDROP HAS BEEN DEELIVERED!**\n\n" ..
            "*Join the server to see precise map location.*\n\n" ..
            "----------------------------------------"
    },
    Spawn = -- Spawn settings
    {
        [AirdropType.Low] = 
        {
            min_players = 5,
            map_preview = -- Preview on discord and ingame map
            {
                time = 0.1, -- How many minutes it appears on the map before it drops
                size = 1000 -- How big is the radius around it
            },
            interval = 60 -- 60 minutes between airdrops of this type
        },
        [AirdropType.Mid] = 
        {
            min_players = 6,
            map_preview = 
            {
                time = 0.1,
                size = 1500
            },
            interval = 240 -- 4 hours between airdrops
        },
        [AirdropType.High] = 
        {
            min_players = 7,
            map_preview = 
            {
                time = 0.1,
                size = 3000
            },
            interval = 480 -- 8 hours between airdrops
        }
    },

}