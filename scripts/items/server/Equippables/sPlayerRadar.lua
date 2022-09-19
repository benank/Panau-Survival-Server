local players_using_radar = {}

local radar_data = ItemsConfig.equippables["Player Radar"]
if not radar_data then
    error("Player Radar not found in ItemsConfig")
    return
end

local function HasAtLeastOneBattery(player)
    return Inventory.GetNumOfItem({player = player, item_name = "Battery"}) > 0
end

local function UnequipPlayerRadar(player, item, index)
    
    local inv = Inventory.Get({player = player}) -- Refresh inventory
    
    local cat_stacks = inv[item.category]
    
    -- Update index in case it changed
    for stack_index, stack in pairs(cat_stacks) do
        if stack.contents[1].uid == item.uid then
            index = stack_index
            break
        end
    end

    local stack = inv[item.category][index]

    if stack and stack:GetProperty("name") == item.name then
        Inventory.SetItemEquipped({
            player = player,
            item = stack.contents[1]:GetSyncObject(),
            index = index,
            equipped = false
        })
    end

end

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Player Radar" then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    if not args.item.equipped then
        players_using_radar[tostring(args.player:GetSteamId())] = nil
    else
        players_using_radar[tostring(args.player:GetSteamId())] = args
    end
    
    -- Unequip if they don't have a battery
    if not HasAtLeastOneBattery(args.player) and args.item.equipped then
        UnequipPlayerRadar(args.player, args.item, args.index)
        Chat:Send(args.player, "Player Radar requires batteries to use!", Color.Red)
    end

end)

local function DecreaseDuraOfBattery(player)

    if not IsValid(player) or not IsPlayerActive(player) then return end

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
        battery_item.durability = battery_item.durability - radar_data.battery_dura_per_sec
        Inventory.ModifyDurability({
            player = player,
            item = battery_item:GetSyncObject()
        })
    end

end

local function GetNearbyPlayers(player)
    local nearby = {}
    
    if not IsValid(player) then return nearby end
    
    local radar_position = player:GetPosition()
    local range = ItemsConfig.equippables["Player Radar"].range
    
    for p in Server:GetPlayers() do
        local player_position = p:GetPosition()
        if p ~= player 
        and not AreFriends(player, tostring(p:GetSteamId())) 
        and p:GetHealth() > 0
        and IsPlayerActive(p)
        and not p:GetValue("dead")
        and not p:GetValue("Invisible")
        and not p:GetValue("StealthEnabled")
        and player_position:Distance(radar_position) < range then
            table.insert(nearby, player_position)
        end
    end
    
    return nearby
end

local function UpdatePlayerRadars()
    
    local sleep_amount = 5000

    for steam_id, args in pairs(players_using_radar) do
        if not IsValid(args.player) or not IsPlayerActive(args.player) then
            players_using_radar[steam_id] = nil
        else
            
            -- Unequip if they don't have a battery
            if not HasAtLeastOneBattery(args.player) then
                UnequipPlayerRadar(args.player, args.item, args.index)
                Chat:Send(args.player, "Player Radar requires batteries to use!", Color.Red)
            else
                
                local nearby_players = GetNearbyPlayers(args.player)
                
                args.item.durability = args.item.durability - ItemsConfig.equippables[args.item.name].dura_per_sec
                Inventory.ModifyDurability({
                    player = args.player,
                    item = args.item
                })
                UpdateEquippedItem(args.player, "Player Radar", args.item)
                DecreaseDuraOfBattery(args.player)
                
                Timer.Sleep(1)
                sleep_amount = sleep_amount - 1
                
                Network:Send(args.player, "items/UpdateRadarPlayers", nearby_players)
            end
        end
    end
    
    Timer.Sleep(sleep_amount)
    
end

Events:Subscribe("ModuleLoad", function()
    Thread(function()
        while true do
            UpdatePlayerRadars()
        end
    end)
end)
