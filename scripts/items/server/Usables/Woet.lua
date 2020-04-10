Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed then

        local entity = args.forward_ray.entity

        if not IsValid(entity) or entity.__type ~= "Vehicle" then
            Chat:Send(player, "You must aim at a vehicle to use this item!", Color.Red)
            return
        end

        if player:GetPosition():Distance(args.forward_ray.position) > ItemsConfig.usables[player_iu.item.name].range then
            Chat:Send(player, "You must move closer to the vehicle to use this item!", Color.Red)
            return
        end

        if math.abs(entity:GetLinearVelocity().z) > 1 then
            Chat:Send(player, "The vehicle must not be moving in order to use this item!", Color.Red)
            return
        end

        entity:SetAngularVelocity(Vector3(0, 0, 15))

        -- Possibly check if they are the owner/friend of owner

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)