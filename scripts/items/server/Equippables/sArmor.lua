Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.armor[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    -- use net vals for sync
    --Network:Send(args.player, "items/ToggleEquippedGrapplehook", {equipped = args.item.equipped == true})

end)
