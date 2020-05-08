local death_positions = {}

Events:Subscribe("PlayerDeath", function(args)
    death_positions[tostring(args.player:GetSteamId())] = args.player:GetPosition()
end)

Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "BackTrack" then

        local death_pos = death_positions[tostring(player:GetSteamId())]

        if not death_pos then
            Chat:Send(player, "No recent death position!", Color.Red)
            return
        end

        Chat:Send(player, "Waypoint set to last death position!", Color.Yellow)

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        Network:Send(player, "items/BackTrack", {position = death_pos})

    end

end)
