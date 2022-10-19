Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and ItemsConfig.usables[player_iu.item.name] and player_iu.item.name == "Drone" then

        Events:Fire("items/SpawnDrone", {
            level = player_iu.item.custom_data.level or 1,
            config = {
                owner_id = tostring(player:GetSteamId()),
                player_owned = true
            },
            static = true,
            tether_position = player:GetPosition(),
            tether_range = 1000,
            position = player:GetPosition() + Vector3.Up * 2,
            player = player
        })

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })


    end

end)