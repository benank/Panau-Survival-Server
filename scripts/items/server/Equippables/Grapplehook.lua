Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Grapplehook" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleEquippedGrapplehook", {equipped = args.item.equipped == true})

end)

Network:Subscribe("items/GrapplehookDecreaseDura", function(args, player)

    local item = GetEquippedItem("Grapplehook", player)
    if not item then return end
    local change = tonumber(args.change)
    if change < 1 or not change then change = 1 end

    item.durability = item.durability - change * ItemsConfig.equippables["Grapplehook"].dura_per_sec
    Inventory.ModifyDurability({
        player = player,
        item = item
    })
    UpdateEquippedItem(player, "Grapplehook", item)

end)