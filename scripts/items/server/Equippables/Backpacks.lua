Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.backpacks[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    local slots = ItemsConfig.equippables.backpacks[args.item.name].slots

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    Events:Fire("Inventory.ToggleBackpackEquipped-" .. tostring(args.player:GetSteamId().id), 
        {equipped = args.item.equipped == true, no_sync = args.no_sync, slots = slots})

end)

local backpack_hits = {}

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

    local steam_id = tostring(args.player:GetSteamId())
    if not backpack_hits[steam_id] then
        backpack_hits[steam_id] = {}
    end

    if not backpack_hits[steam_id][item.name] then
        backpack_hits[steam_id][item.name] = {
            player = args.player,
            dura = change * ItemsConfig.equippables.backpacks[item.name].dura_per_hit,
            item = item
        }
    else
        backpack_hits[steam_id][item.name].dura = backpack_hits[steam_id][item.name].dura +
            change * ItemsConfig.equippables.backpacks[item.name].dura_per_hit
        backpack_hits[steam_id][item.name].item = item
    end

end

Events:Subscribe("HitDetection/PlayerExplosionHit", function(args) ModifyBackpackDurability(args) end)
Events:Subscribe("HitDetection/PlayerBulletHit", function(args) ModifyBackpackDurability(args) end)


Thread(function()
    while true do
        log_function_call("backpacks local func = (function()")
        for steam_id, data in pairs(backpack_hits) do
            for item_name, item_hits in pairs(data) do

                if IsValid(item_hits.player) then
                    local item = item_hits.item

                    item.durability = item.durability - item_hits.dura
                    Inventory.ModifyDurability({
                        player = item_hits.player,
                        item = item
                    })

                    UpdateEquippedItem(item_hits.player, item.name, item)

                end

                backpack_hits[steam_id][item_name] = nil
                Timer.Sleep(500)

            end

            if count_table(backpack_hits[steam_id]) == 0 then
                backpack_hits[steam_id] = nil
            end
        end
        log_function_call("backpacks local func = (function() 2")

        Timer.Sleep(500)
    end
end)