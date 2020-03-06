Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.backpacks[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    local slots = ItemsConfig.equippables.backpacks[args.item.name].slots
    
    Events:Fire("Inventory.ToggleBackpackEquipped-" .. tostring(args.player:GetSteamId().id), 
        {equipped = args.item.equipped == true, slots = slots})

end)

function ModifyBackpackDurability(args)

    local item = GetEquippedItem(args.armor_name, args.player)
    if not item then return end
    local change = args.damage
    if change < 1 or not change then change = 1 end

    -- If it is armor, durability will be subtracted in sArmor.lua
    if ItemsConfig.equippables.armor[item.name] then return end

    item.durability = item.durability - change * ItemsConfig.equippables.backpacks[item.name].dura_per_hit
    Inventory.ModifyDurability({
        player = args.player,
        item = item
    })

    UpdateEquippedItem(args.player, item.name, item)

end

Events:Subscribe("HitDetection/PlayerExplosionHit", function(args) ModifyBackpackDurability(args) end)
Events:Subscribe("HitDetection/PlayerBulletHit", function(args) ModifyBackpackDurability(args) end)