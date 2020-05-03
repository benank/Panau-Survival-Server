Events:Subscribe("ClientModuleLoad", function(args)

    -- Set array of equipped items on player for easy lookup by name
    args.player:SetValue("ItemUse", {})

end)

Events:Subscribe("Inventory/UseItem", function(args)

    if not args.item or not IsValid(args.player) then return end

    local player_iu = args.player:GetValue("ItemUse")

    if ItemsConfig.usables[args.item.name] and not player_iu.using then
    
        if args.player:GetValue("StuntingVehicle") then
            Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
            return
        end

        --[[if ItemsConfig.usables[args.item.name].vehicle and not args.player:InVehicle() then
        
            return
        end]]

        --[[if ItemsConfig.usables[args.item.name].storage and 
            (not args.player.current_box or not args.player.current_box.is_storage or not args.player.current_box.storage) then
        
            return
        end

        -- Check if they can hack the storage or apply upgrades, etc
        if ItemsConfig.usables[args.item.name].storage then
            if not args.player.current_box.storage.can_use_item(args.item.name, args.player) then
                return
            end
        end]]


        local use_time = ItemsConfig.usables[args.item.name].use_time

        if not use_time then return end

        Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations
        
        player_iu.using = true
        player_iu.health = args.player:GetHealth()
        player_iu.item = args.item
        player_iu.use_time = use_time
        player_iu.index = args.index
        
        local in_vehicle = ItemsConfig.usables[args.item.name].vehicle == true -- Can't send undefined

        Network:Send(args.player, "items/UseItem", {name = args.item.name, time = use_time, in_vehicle = in_vehicle})
        
        player_iu.timeout = Timer.SetTimeout(use_time * 1000, function()
            local player_iu2 = args.player:GetValue("ItemUse")

            if player_iu2.using then
                player_iu2.completed = true
            else
                player_iu2.using = false
            end
            args.player:SetValue("ItemUse", player_iu2)
        end)

        args.player:SetValue("ItemUse", player_iu)
    end

end)

-- When a player tries to use an item but cancels for some reason
Network:Subscribe("items/CancelUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.using and player_iu.item then
    
        --[[if (reason == 1)
        {
            jcmp.notify(player, {
                title: 'Cannot use item!',
                subtitle: `You must be standing still to use ${player.iu.item.name}!`,
                preset: 'warn'
            })
        }
        else if (reason == 2)
        {
            jcmp.notify(player, {
                title: 'Item usage cancelled!',
                subtitle: `You took damage, so usage of ${player.iu.item.name} was cancelled.`,
                preset: 'warn'
            })

        }
        else if (reason == 3)
        {
            jcmp.notify(player, {
                title: 'Item usage cancelled!',
                subtitle: `Usage of ${player.iu.item.name} was cancelled.`,
                preset: 'warn'
            })
        }--]]

        Inventory.OperationBlock({player = player, change = -1})
    end

    player:SetValue("ItemUse", {})
    Timer.Clear(player_iu.timeout)
end)

Network:Subscribe("items/CompleteItemUsage", function(args, player)

    Timer.SetTimeout(100, function() 
        player:SetValue("ItemUse", {})
    end)

    Timer.SetTimeout(1000, function() 
        Inventory.OperationBlock({player = player, change = -1})
    end);
        
end)