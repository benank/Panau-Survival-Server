Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.armor[args.item.name] then return end

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    UpdateEquippedItemSurvivalHUD(args)
    UpdateEquippedItem(args.player, args.item.name, args.item)

end)

Events:Subscribe("HitDetection/ArmorDamaged", function(args)

    if not IsValid(args.player) then return end
    local item = GetEquippedItem(args.armor_name, args.player)
    if not item then return end
    local change = args.damage_diff
    if not change or change < 1 then change = 1 end

    item.durability = item.durability - change * ItemsConfig.equippables.armor[item.name].dura_per_hit
    Inventory.ModifyDurability({
        player = args.player,
        item = item
    })

    args.item = item
    UpdateEquippedItemSurvivalHUD(args)
    UpdateEquippedItem(args.player, item.name, item)

end)

function UpdateEquippedItemSurvivalHUD(args)

    if args.item.name:find("Helmet") then
        args.player:SetNetworkValue("EquippedHelmet", (args.item.equipped == true and args.item.durability > 0) and args.item or nil)
    elseif args.item.name:find("Vest") then
        args.player:SetNetworkValue("EquippedVest", (args.item.equipped == true and args.item.durability > 0) and args.item or nil)
    end

end