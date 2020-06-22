Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "RocketGrapple" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    args.player:SetNetworkValue("RocketGrappleEquipped", args.item.equipped == true)

    Network:Send(args.player, "items/ToggleEquippedRocketGrapple", {equipped = args.item.equipped == true, uid = args.item.uid})

end)

Network:Subscribe("items/RocketGrappleDecreaseDura", function(args, player)

    local item = GetEquippedItem("RocketGrapple", player)
    if not item then return end
    local change = tonumber(args.change)
    if change < 1 or not change then change = 1 end

    if item.uid ~= args.uid then
        UpdateEquippedItem(player, "Grapplehook", nil)
    end

    item.durability = item.durability - math.ceil(change * ItemsConfig.equippables["RocketGrapple"].dura_per_sec)
    Inventory.ModifyDurability({
        player = player,
        item = item
    })
    UpdateEquippedItem(player, "RocketGrapple", item)

end)