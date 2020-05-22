Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Hoverboard" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    args.player:SetNetworkValue("HoverboardEquipped", args.item.equipped == true)

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleEquippedHoverboard", {equipped = args.item.equipped == true})

end)

Network:Subscribe("items/HoverboardDecreaseDura", function(args, player)

    local item = GetEquippedItem("Hoverboard", player)
    if not item then return end

    item.durability = item.durability - ItemsConfig.equippables["Hoverboard"].dura_per_5_sec
    Inventory.ModifyDurability({
        player = player,
        item = item
    })
    UpdateEquippedItem(player, "Hoverboard", item)

end)