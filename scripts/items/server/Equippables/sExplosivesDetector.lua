local dura_data = ItemsConfig.equippables["Explosives Detector"]
if not dura_data then
    error("Explosives Detector not found in ItemsConfig")
    return
end

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Explosives Detector" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedExplosivesDetector", {equipped = args.item.equipped == true})

    if not args.initial and args.item.equipped then
        args.item.durability = args.item.durability - dura_data.dura_per_activation
        Inventory.ModifyDurability({
            player = args.player,
            item = args.item
        })
    end

    UpdateEquippedItem(args.player, args.item.name, args.item)

end)

ExplosivesDetectorPerks = 
{
    [57] = {[1] = 0.75},
    [116] = {[1] = 0.5}
}

Timer.SetInterval(5000, function()

    for p in Server:GetPlayers() do
        if IsValid(p) then
            local item = GetEquippedItem("Explosives Detector", p)
            if item then

                local perks = p:GetValue("Perks")
                local perk_modifier = 1

                for perk_id, perk_data in pairs(ExplosivesDetectorPerks) do
                    local choice = perks.unlocked_perks[perk_id]
                    if choice and perk_data[choice] then
                        perk_modifier = math.min(perk_modifier, perk_data[choice])
                    end
                end

                item.durability = item.durability - math.min(1, math.floor(dura_data.dura_per_sec * perk_modifier))
                Inventory.ModifyDurability({
                    player = p,
                    item = item
                })

                UpdateEquippedItem(p, "Explosives Detector", item)
                DecreaseDuraOfBattery(p)

            end
        end
    end

end)

function DecreaseDuraOfBattery(player)

    if not IsValid(player) then return end

    local inv = Inventory.Get({player = player})
    if not inv then return end
    
    local item = Items_indexed["Battery"]
    if not item then
        print("Failed to DecreaseDuraOfBattery because item was invalid")
        return
    end

    local battery_item = nil

    for index, stack in pairs(inv[item.category]) do
        if stack:GetProperty("name") == item.name then
            battery_item = stack.contents[1]
            break
        end
    end

    if battery_item then
        battery_item.durability = battery_item.durability - dura_data.battery_dura_per_sec
        Inventory.ModifyDurability({
            player = player,
            item = battery_item:GetSyncObject()
        })
    end

end