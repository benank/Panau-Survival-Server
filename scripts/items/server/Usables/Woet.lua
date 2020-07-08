Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
    player_iu.item.name == "Woet" then

        local entity = args.forward_ray.entity

        if not IsValid(entity) or entity.__type ~= "Vehicle" then
            Chat:Send(player, "You must aim at a vehicle to use this item!", Color.Red)
            return
        end

        if player:GetPosition():Distance(args.forward_ray.position) > ItemsConfig.usables[player_iu.item.name].range then
            Chat:Send(player, "You must move closer to the vehicle to use this item!", Color.Red)
            return
        end

        if tonumber(player_iu.item.custom_data.woet_x) == 0 then
            entity:SetAngularVelocity(Vector3(0, 0, 15))
        else
            local angle = entity:GetAngle()
            angle.roll = 0
            entity:SetAngle(angle)
        end

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)