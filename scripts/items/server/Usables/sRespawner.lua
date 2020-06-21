Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Respawner" then

        local BlacklistedAreas = SharedObject.GetByName("BlacklistedAreas"):GetValues().blacklist

        local pos = player:GetPosition()
        for _, area in pairs(BlacklistedAreas) do
            if pos:Distance(area.pos) < area.size then
                Chat:Send(player, "You cannot use a respawner here!", Color.Red)
                return
            end
        end

        player:SetValue("RespawnerLastSet", Server:GetElapsedSeconds())
    
        Events:Fire("SetHomePosition", {
            player = player,
            pos = player:GetPosition()
        })

        Chat:Send(player, "Respawn position set!", Color.Yellow)

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)
