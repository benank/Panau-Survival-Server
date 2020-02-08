Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and ItemsConfig.usables[player_iu.item.name].restore_hp then

        local new_hp = math.min(player:GetHealth() + ItemsConfig.usables[player_iu.item.name].restore_hp, 1)
        player:SetHealth(new_hp)

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)