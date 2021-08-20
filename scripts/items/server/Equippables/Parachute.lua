
local players_with_parachutes = {}

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Parachute" and args.item.name ~= "RocketPara" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedParachute", 
    {
        equipped = args.item.equipped == true, 
        uid = args.item.uid,
        name = args.item.name
    })
    
    UpdateEquippedItem(args.player, args.item.name, args.item)
    args.player:SetNetworkValue("ThrustersActive", nil) 

    if args.item.equipped then
        args.player:SetValue("ParachutingValue", 0)
        players_with_parachutes[args.player:GetId()] = args.player
        args.player:SetValue("ParachuteType", args.item.name)
    else
        players_with_parachutes[args.player:GetId()] = nil
        args.player:SetValue("ParachuteType", nil)
    end

end)


Network:Subscribe("items/ActivateParaThrusters", function(args, player)
    local parachute_type = player:GetValue("ParachuteType")
    local item = GetEquippedItem(parachute_type, player)

    if not item then return end

    player:SetNetworkValue("ThrustersActive", true)
end)

Network:Subscribe("items/DeactivateParaThrusters", function(args, player)
    player:SetNetworkValue("ThrustersActive", nil)
end)

Events:Subscribe("SecondTick", function()
    for player in Server:GetPlayers() do
        if IsValid(player) and players_with_parachutes[player:GetId()] then
            if player:GetValue("ParachutingValue") and player:GetParachuting() then
                local parachute_type = player:GetValue("ParachuteType")
                local dura_per_sec = ItemsConfig.equippables[parachute_type].dura_per_sec
                player:SetValue("ParachutingValue", player:GetValue("ParachutingValue") + dura_per_sec)
            end
        elseif IsValid(player) then
            players_with_parachutes[player:GetId()] = nil
        end
    end
end)

local parachute_perks =
{
    [43] = 1 - (0.10 / 2), -- 10%
    [89] = 1 - (0.25 / 2), -- 25%
    [130] = 1 - (0.50 / 2), -- 50%
    [156] = 1 - (0.75 / 2), -- 75%
    [175] = 1 - (1.00 / 2) -- 100% extra
}

Timer.SetInterval(5000, function()

    for player in Server:GetPlayers() do

        if IsValid(player) then
            local parachuting_value = player:GetValue("ParachutingValue")

            if parachuting_value and parachuting_value > 0 then
                local parachute_type = player:GetValue("ParachuteType")
                local item = GetEquippedItem(parachute_type, player)
                
                if not item then return end

                local perks = player:GetValue("Perks")
                local perk_mod = 1

                for perk_id, dura_mod in pairs(parachute_perks) do
                    if perks.unlocked_perks[perk_id] then
                        perk_mod = math.min(perk_mod, dura_mod)
                    end
                end

                item.durability = item.durability - math.max(1, math.floor(parachuting_value * perk_mod))
                Inventory.ModifyDurability({
                    player = player,
                    item = item
                })
                UpdateEquippedItem(player, parachute_type, item)
                player:SetValue("ParachutingValue", 0)

            end
        end

    end

end)


Network:Subscribe("items/ParaDecreaseDura", function(args, player)

    local parachute_type = player:GetValue("ParachuteType")
    local item = GetEquippedItem(parachute_type, player)
    if not item then return end
    local change = tonumber(args.change)
    if change < 1 or not change then change = 1 end

    if item.uid ~= args.uid then return end

    local inv = Inventory.Get({player = player})

    local stack_index = -1

    for index, stack in pairs(inv[item.category]) do
        for _, _item in pairs(stack.contents) do
            if _item.uid == item.uid then
                stack_index = index
                break
            end
        end
    end

    local perks = player:GetValue("Perks")
    local perk_mod = 1

    for perk_id, dura_mod in pairs(parachute_perks) do
        if perks.unlocked_perks[perk_id] then
            perk_mod = math.min(perk_mod, dura_mod)
        end
    end

    item.durability = item.durability - change * math.ceil(ItemsConfig.equippables[parachute_type].dura_per_use_sec * perk_mod)
    Inventory.ModifyDurability({
        player = player,
        item = item
    })

    UpdateEquippedItem(player, parachute_type, item)
end)
