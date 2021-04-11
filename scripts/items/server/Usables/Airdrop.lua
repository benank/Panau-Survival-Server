Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Airdrop" then

        if args.down_ray.position:Distance(player:GetPosition()) > 500
        or args.ray.position:Distance(player:GetPosition()) > 4 then
            Chat:Send(player, "You must stand on solid ground to use this.", Color.Red)
            return
        end

        local position = args.down_ray.position
        if position.y < 200 then
            position.y = 200
        end

        local sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
        if position:Distance(sz_config.neutralzone.position) < sz_config.neutralzone.radius then
            Chat:Send(player, "You cannot use this while in the neutralzone.", Color.Red)
            return
        end
        
        Events:Fire("items/UseAirdrop", {
            player = player,
            position = position,
            player_iu = player_iu
        })

    end

end)