local nitro_perks = 
{
    [27] = 
    {
        [1] = 0.2
    },
    [81] = 
    {
        [1] = 0.2
    },
    [121] = 
    {
        [1] = 0.2
    }
}


Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Nitro" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleEquippedNitro", {equipped = args.item.equipped == true, uid = args.item.uid})

end)

Events:Subscribe("PlayerExitVehicle", function(args)
    args.vehicle:SetNetworkValue("NitroActive", nil)
end)

Events:Subscribe("PlayerQuit", function(args)
    if args.player:InVehicle() then
        args.player:GetVehicle():SetNetworkValue("NitroActive", nil)
    end
end)

Network:Subscribe("items/NitroDecreaseDura", function(args, player)

    local item = GetEquippedItem("Nitro", player)
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

    local perk_modifier = 1

    for perk_id, data in pairs(nitro_perks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and nitro_perks[perk_id][choice] then
            perk_modifier = perk_modifier - nitro_perks[perk_id][choice]
        end
    end

    item.durability = item.durability - change * math.ceil(ItemsConfig.equippables["Nitro"].dura_per_sec * perk_modifier)
    Inventory.ModifyDurability({
        player = player,
        item = item
    })

    UpdateEquippedItem(player, "Nitro", item)

    if item.durability <= 0 then

        inv = Inventory.Get({player = player}) -- Refresh inventory

        if player:InVehicle() then
            player:GetVehicle():SetNetworkValue("NitroActive", nil)
        end
        
        -- If there is another nitro in the stack, equip it
        local stack = inv[item.category][stack_index]

        if stack and stack:GetProperty("name") == item.name then
            Inventory.SetItemEquipped({
                player = player,
                item = stack.contents[1]:GetSyncObject(),
                index = stack_index,
                equipped = true
            })
        end

    end


end)

Network:Subscribe("items/ActivateNitro", function(args, player)

    if not player:InVehicle() then return end

    local v = player:GetVehicle()

    v:SetNetworkValue("NitroActive", true)

end)

Network:Subscribe("items/DeactivateNitro", function(args, player)

    if not args.id then return end

    local v = Vehicle.GetById(args.id)

    if not IsValid(v) then return end

    v:SetNetworkValue("NitroActive", nil)

end)