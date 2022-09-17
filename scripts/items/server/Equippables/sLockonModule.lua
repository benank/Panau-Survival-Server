Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Lock-On Module" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleEquippedLockonModule", {equipped = args.item.equipped == true, uid = args.item.uid})

end)

Events:Subscribe("items/AmmoUsed", function(args)
    
    local item = GetEquippedItem("Lock-On Module", args.player)
    if not item then return end
    
    item.durability = item.durability - math.ceil(args.ammo_used * ItemsConfig.equippables["Lock-On Module"].dura_per_bullet)
    Inventory.ModifyDurability({
        player = args.player,
        item = item
    })
    UpdateEquippedItem(args.player, "Lock-On Module", item)
    
end)