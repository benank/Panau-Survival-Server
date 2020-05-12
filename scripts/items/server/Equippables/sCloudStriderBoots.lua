Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Cloud Strider Boots" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    args.player:SetNetworkValue("CloudStriderBootsEquipped", args.item.equipped == true)

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleEquippedCloudStriderBoots", {equipped = args.item.equipped == true})

end)

Network:Subscribe("items/CloudStriderBootsDecreaseDura", function(args, player)

    local item = GetEquippedItem("Cloud Strider Boots", player)
    if not item then return end

    item.durability = item.durability - ItemsConfig.equippables["Cloud Strider Boots"].dura_per_5_sec
    Inventory.ModifyDurability({
        player = player,
        item = item
    })
    UpdateEquippedItem(player, "Cloud Strider Boots", item)

end)