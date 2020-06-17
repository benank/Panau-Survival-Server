Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.backpacks[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    local equipped_visuals = args.player:GetValue("EquippedVisuals")
    equipped_visuals[args.item.name] = args.item.equipped
    args.player:SetNetworkValue("EquippedVisuals", equipped_visuals)

    if args.item.name ~= "Combat Backpack" and args.item.name ~= "Explorer Backpack" then

        Events:Fire("Inventory.ToggleBackpackEquipped-" .. tostring(args.player:GetSteamId().id), 
            {equipped = args.item.equipped == true, name = args.item.name, slots = ItemsConfig.equippables.backpacks[args.item.name].slots})

    else
        UpdateBackpackSlots(args.player, args.item)
    end

end)

function GetBackpackSlots(type, perks)

    local slots = deepcopy(ItemsConfig.equippables.backpacks[type].slots)

    local choice_index = type == "Combat Backpack" and 1 or 2

    for perk_id, choice in pairs(perks.unlocked_perks) do
        if BackpackPerks[perk_id] and choice == choice_index then
            for category, bonus in pairs(BackpackPerks[perk_id][choice_index]) do
                slots[category] = slots[category] + bonus
            end
        end
    end

    return slots

end

Events:Subscribe("PlayerPerksUpdated", function(args)
    UpdateBackpackSlots(args.player, GetEquippedItem("Combat Backpack", args.player) or GetEquippedItem("Explorer Backpack", args.player))
end)

function UpdateBackpackSlots(player, item)

    if not item then return end

    local perks = player:GetValue("Perks")

    if not perks then return end

    Events:Fire("Inventory.ToggleBackpackEquipped-" .. tostring(player:GetSteamId().id), 
        {equipped = item.equipped == true, name = item.name, slots = GetBackpackSlots(item.name, perks)})

end

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


Timer.SetInterval(500, function()
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

        end

        if count_table(backpack_hits[steam_id]) == 0 then
            backpack_hits[steam_id] = nil
        end
    end

end)