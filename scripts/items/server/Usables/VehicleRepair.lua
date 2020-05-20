Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
    player_iu.item.name == "Vehicle Repair" then

        local entity = args.forward_ray.entity

        if not IsValid(entity) or entity.__type ~= "Vehicle" then
            Chat:Send(player, "You must aim at a vehicle to use this item!", Color.Red)
            return
        end

        if player:GetPosition():Distance(args.forward_ray.position) > ItemsConfig.usables[player_iu.item.name].range then
            Chat:Send(player, "You must move closer to the vehicle to use this item!", Color.Red)
            return
        end

        if entity:GetHealth() <= 0.2 then
            Chat:Send(player, "This vehicle is damaged beyond repair!", Color.Red)
            return
        end

        if count_table(entity:GetOccupants()) > 0 then
            Chat:Send(player, "This vehicle must be unoccupied!", Color.Red)
            return
        end


        entity:SetHealth(1)
        entity:SetSpawnPosition(entity:GetPosition())
        entity:SetSpawnAngle(entity:GetAngle())
        entity:Respawn()

        Timer.SetTimeout(2000, function()
            entity:SetHealth(1)
        end)

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)