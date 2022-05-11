Events:Subscribe("ClientModuleLoad", function(args)
    
    Timer.SetTimeout(2000, function()
        if not IsValid(args.player) then return end
        
        local steamID = tostring(args.player:GetSteamId())
        local player_stats = {}
        
        local player_data = SQL:Query("SELECT * FROM player_data WHERE steamID = ? LIMIT 1")
        player_data:Bind(1, steamID)
        player_data = player_data:Execute()
        if player_data and player_data[1] then
            player_stats.kills = player_data[1].kills
            player_stats.deaths = player_data[1].deaths
            player_stats.time_online = player_data[1].time_online / 60
            player_stats.tier1_looted = player_data[1].tier1_looted
            player_stats.tier2_looted = player_data[1].tier2_looted
            player_stats.tier3_looted = player_data[1].tier3_looted
            player_stats.tier4_looted = player_data[1].tier4_looted
            player_stats.total_boxes_looted = player_stats.tier1_looted
                                            + player_stats.tier2_looted
                                            + player_stats.tier3_looted
                                            + player_stats.tier4_looted
            player_stats.stashes_hacked = player_data[1].stashes_hacked
        end
        
        local exp = SQL:Query("SELECT * FROM exp WHERE steamID = ? LIMIT 1")
        exp:Bind(1, steamID)
        exp = exp:Execute()
        if exp and exp[1] then
            player_stats.level = exp[1].level
            player_stats.exp = exp[1].combat_exp + exp[1].explore_exp
            player_stats.max_exp = GetMaximumExp(player_stats.level)
        end
        
        local dk = SQL:Query("SELECT * FROM drone_kills WHERE steam_id = ? LIMIT 1")
        dk:Bind(1, steamID)
        dk = dk:Execute()
        if dk and dk[1] then
            player_stats.drone_kills = dk[1].kills
        end
        
        Network:Send(args.player, "Exp/UpdatePlayerStats", player_stats)
    end)
    
end)