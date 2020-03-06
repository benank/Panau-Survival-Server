Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.armor[args.item.name] then return end

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    UpdateEquippedItem(args.player, args.item.name, args.item)

end)

Events:Subscribe("HitDetection/ArmorDamaged", function(args)

    local item = GetEquippedItem(args.armor_name, args.player)
    if not item then return end
    local change = args.damage
    if change < 1 or not change then change = 1 end

    item.durability = item.durability - change * ItemsConfig.equippables.armor[item.name].dura_per_hit
    Inventory.ModifyDurability({
        player = args.player,
        item = item
    })

    UpdateEquippedItem(args.player, item.name, item)

end)