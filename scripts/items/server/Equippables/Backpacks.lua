Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.backpacks[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    local slots = ItemsConfig.equippables.backpacks[args.item.name].slots

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    Events:Fire("Inventory.ToggleBackpackEquipped-" .. tostring(args.player:GetSteamId().id), 
        {equipped = args.item.equipped == true, slots = slots})

end)

function ModifyBackpackDurability(args)

    local item

    local equipped_items = args.player:GetValue("EquippedItems")

    for name, _item in pairs(equipped_items) do
        if ItemsConfig.equippables.backpacks[name] then
            item = _item
            break
        end
    end

    if not item then return end
    local change = args.damage
    if change < 1 or not change then change = 1 end

    -- If it is armor, durability will be subtracted in sArmor.lua
    if ItemsConfig.equippables.armor[item.name] then return end

    print("sub " .. tostring(change))

    item.durability = item.durability - change * ItemsConfig.equippables.backpacks[item.name].dura_per_hit
    Inventory.ModifyDurability({
        player = args.player,
        item = item
    })

    UpdateEquippedItem(args.player, item.name, item)

end

Events:Subscribe("HitDetection/PlayerExplosionHit", function(args) ModifyBackpackDurability(args) end)
Events:Subscribe("HitDetection/PlayerBulletHit", function(args) ModifyBackpackDurability(args) end)