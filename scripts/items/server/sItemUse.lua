class 'sItemUse'

function sItemUse:__init()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("Inventory/UseItem", self, self.InventoryUseItem)

    Network:Subscribe("items/CancelUsage", self, self.CancelUsage)
    Network:Subscribe("items/CompleteItemUsage", self, self.CompleteItemUsage)
end

function sItemUse:ClientModuleLoad(args)

    -- Set array of equipped items on player for easy lookup by name
    args.player:SetValue("ItemUse", {})

end

function sItemUse:InventoryUseItem(args)

    if not args.item or not IsValid(args.player) then return end

    Events:Fire("Discord", {
        channel = "Item Usage",
        content = string.format("%s [%s] used %s", args.player:GetName(), tostring(args.player:GetSteamId()), args.item.name)
    })

    local player_iu = args.player:GetValue("ItemUse")

    if ItemsConfig.usables[args.item.name] and not player_iu.using then
    
        if args.player:GetValue("StuntingVehicle") then
            Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
            return
        end

        local use_time = ItemsConfig.usables[args.item.name].use_time

        if not use_time then return end
        if ItemsConfig.usables[args.item.name].delay_use and not args.delayed then return end

        Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations

        local perks = args.player:GetValue("Perks")
        local perk_use_time_mod = 1
        local item_perks = ItemsConfig.use_time_perks[args.item.name]

        if perks and item_perks then

            for perk_id, use_time_modifier in pairs(item_perks) do
                if perks.unlocked_perks[perk_id] then
                    perk_use_time_mod = math.min(perk_use_time_mod, use_time_modifier)
                end
            end

        end

        use_time = use_time * perk_use_time_mod
        
        player_iu.using = true
        player_iu.health = args.player:GetHealth()
        player_iu.item = args.item
        player_iu.use_time = use_time
        player_iu.index = args.index
        
        local in_vehicle = ItemsConfig.usables[args.item.name].vehicle == true -- Can't send undefined

        Network:Send(args.player, "items/UseItem", {name = args.item.name, time = use_time, in_vehicle = in_vehicle})
        
        player_iu.timeout = Timer.SetTimeout(use_time * 1000, function()
            if not IsValid(args.player) then return end
            
            local player_iu2 = args.player:GetValue("ItemUse")

            if player_iu2.using then
                player_iu2.completed = true
            else
                player_iu2.using = false
            end
            args.player:SetValue("ItemUse", player_iu2)

            Events:Fire("Discord", {
                channel = "Item Usage",
                content = string.format("%s [%s] finished using %s", args.player:GetName(), tostring(args.player:GetSteamId()), args.item.name)
            })

        end)

        args.player:SetValue("ItemUse", player_iu)
    end

end

-- When a player tries to use an item but cancels for some reason
function sItemUse:CancelUsage(args, player)

    Events:Fire("ItemUse/CancelUsage", {player = player})

    local player_iu = player:GetValue("ItemUse")

    if player_iu.using and player_iu.item then
        Inventory.OperationBlock({player = player, change = -1})
    end

    player:SetValue("ItemUse", {})
    Timer.Clear(player_iu.timeout)

end

function sItemUse:CompleteItemUsage(args, player)

    Timer.SetTimeout(100, function() 
        if IsValid(player) then
            player:SetValue("ItemUse", {})
        end
    end)

    Timer.SetTimeout(1000, function() 
        if IsValid(player) then
            Inventory.OperationBlock({player = player, change = -1})
        end
    end);
        
end

sItemUse = sItemUse()