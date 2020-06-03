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

Thread(function()

    while true do

        log_function_call("sExplosivesDetector check")
        Timer.Sleep(1000)

        for p in Server:GetPlayers() do
            if IsValid(p) then
                local item = GetEquippedItem("Explosives Detector", p)
                if item then

                    item.durability = item.durability - dura_data.dura_per_sec
                    Inventory.ModifyDurability({
                        player = p,
                        item = item
                    })

                    UpdateEquippedItem(p, "Explosives Detector", item)
                    DecreaseDuraOfBattery(p)

                    Timer.Sleep(1)
                end
            end
        end
        log_function_call("sExplosivesDetector check 2")

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