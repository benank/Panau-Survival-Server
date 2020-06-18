Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Stick Disguise" then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    args.player:SetNetworkValue("StickDisguiseEquipped", args.item.equipped == true)

    if args.item.equipped then
        if args.player:GetModelId() ~= 20 then
            args.player:SetValue("ModelId", args.player:GetModelId())
        end
        args.player:SetModelId(20)
    else
        args.player:SetModelId(args.player:GetValue("ModelId"))
    end

end)

local disguise_hits = {}

local function ModifyDisguiseDurability(args)

    local equipped_items = args.player:GetValue("EquippedItems")
    local item = equipped_items["Stick Disguise"]

    if not item then return end
    local change = args.damage
    if change < 1 or not change then change = 1 end

    if not ItemsConfig.equippables["Stick Disguise"] then return end

    local steam_id = tostring(args.player:GetSteamId())
    if not disguise_hits[steam_id] then
        disguise_hits[steam_id] = {}
    end

    if not disguise_hits[steam_id]["Stick Disguise"] then
        disguise_hits[steam_id]["Stick Disguise"] = {
            player = args.player,
            dura = change * ItemsConfig.equippables["Stick Disguise"].dura_per_hit,
            item = item
        }
    else
        disguise_hits[steam_id]["Stick Disguise"].dura = disguise_hits[steam_id]["Stick Disguise"].dura +
            change * ItemsConfig.equippables["Stick Disguise"].dura_per_hit
            disguise_hits[steam_id]["Stick Disguise"].item = item
    end

end

Events:Subscribe("HitDetection/PlayerExplosionHit", function(args) ModifyDisguiseDurability(args) end)
Events:Subscribe("HitDetection/PlayerBulletHit", function(args) ModifyDisguiseDurability(args) end)


Timer.SetInterval(1000, function()
    for steam_id, data in pairs(disguise_hits) do
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

            disguise_hits[steam_id][item_name] = nil

        end

        if count_table(disguise_hits[steam_id]) == 0 then
            disguise_hits[steam_id] = nil
        end
    end

end)