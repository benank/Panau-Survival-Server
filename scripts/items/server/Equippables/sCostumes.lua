Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.costumes[args.item.name] then return end

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    UpdateEquippedItem(args.player, args.item.name, args.item)

end)


local costume_hits = {}

local function ModifyCostumeDurability(args)

    local equipped_items = args.player:GetValue("EquippedItems")

    local change = args.damage
    if change < 1 or not change then change = 1 end

    for equipped_item_name, item in pairs(equipped_items) do

        if ItemsConfig.equippables.costumes[equipped_item_name] then

            local steam_id = tostring(args.player:GetSteamId())
            if not costume_hits[steam_id] then
                costume_hits[steam_id] = {}
            end

            if not costume_hits[steam_id][equipped_item_name] then
                costume_hits[steam_id][equipped_item_name] = {
                    player = args.player,
                    dura = change * ItemsConfig.equippables.costumes[equipped_item_name].dura_per_hit,
                    item = item
                }
            else
                costume_hits[steam_id][equipped_item_name].dura = costume_hits[steam_id][equipped_item_name].dura +
                    change * ItemsConfig.equippables.costumes[equipped_item_name].dura_per_hit
                    costume_hits[steam_id][equipped_item_name].item = item
            end

        end
    end

end

Events:Subscribe("HitDetection/PlayerExplosionHit", function(args) ModifyCostumeDurability(args) end)
Events:Subscribe("HitDetection/PlayerBulletHit", function(args) ModifyCostumeDurability(args) end)

Timer.SetInterval(1000, function()
    for steam_id, data in pairs(costume_hits) do
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

            costume_hits[steam_id][item_name] = nil

        end

        if count_table(costume_hits[steam_id]) == 0 then
            costume_hits[steam_id] = nil
        end
    end

end)