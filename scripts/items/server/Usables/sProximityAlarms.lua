class 'sProxAlarms'

function sProxAlarms:__init()

    self.recent_ids = {}

    self.network_subs = {}
    self.alarms = {}

    self.max_items = 1 -- 1 stack of batteries only

    self.players = {}

    Network:Subscribe("items/CancelProxPlacement", self, self.CancelProxPlacement)
    Network:Subscribe("items/PlaceProx", self, self.FinishProxPlacement)

    Network:Subscribe("items/InsideProximityAlarm", self, self.InsideProximityAlarm)

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)

    Events:Subscribe("ItemUse/CancelUsage", self, self.ItemUseCancelUsage)

    Events:Subscribe("Inventory/RemoveLootbox", self, self.RemoveLootbox)
    Events:Subscribe("Inventory/CreateLootbox", self, self.CreateLootbox)
    Events:Subscribe("Inventory/LootboxUpdated", self, self.LootboxUpdated)
    Events:Subscribe("Items/ChangeAlarmOwnership", self, self.ChangeAlarmOwnership)

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)

    Timer.SetInterval(1000 * 60 * 60, function()
        self:LowerBatteryDurabilities()
    end)
end

function sProxAlarms:ChangeAlarmOwnership(args)
    if self.alarms[args.uid] then
        self.alarms[args.uid].stash.owner_id = args.owner_id
    end
end

function sProxAlarms:ItemExplode(args)

    for id, alarm in pairs(self.alarms) do
        if alarm.position:Distance(args.position) < args.radius then
            self:DestroyProx({id = id}, args.player)
        end
    end

end

function sProxAlarms:ClientModuleLoad(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
end

function sProxAlarms:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function sProxAlarms:LootboxUpdated(args)
    if args.tier ~= 14 then return end -- Not a proximity alarm

    self.alarms[args.uid] = args
end

function sProxAlarms:LowerBatteryDurabilities()

    -- Loop through alarms and lower durabilities
    for id, alarm in pairs(self.alarms) do

        if count_table(alarm.contents) > 0 then
            -- There is at least one battery, so lower its durability

            local contents = {}

            for index, item in pairs(alarm.contents[1].contents) do
                contents[index] = shItem(item)
            end

            local stack = shStack({contents = contents, uid = alarm.contents[1].uid})

            stack.contents[1].durability = stack.contents[1].durability - ItemsConfig.usables["Proximity Alarm"].battery_dura_per_hour

            if stack.contents[1].durability <= 10 then
                stack:RemoveItem(nil, nil, true)

                local coords = alarm.position + Vector3(16384, 0, 16384)

                if stack:GetAmount() == 0 then
                
                    Events:Fire("SendPlayerPersistentMessage", {
                        steam_id = alarm.stash.owner_id,
                        message = string.format("Your proximity alarm ran out of batteries @ X: %.0f Y: %.0f", coords.x, coords.z),
                        color = Color(200, 0, 0)
                    })
                    
                end
            end

            Events:Fire("Inventory/ModifyStashStackRemote", {
                stash_id = id,
                stack = stack:GetSyncObject(),
                stack_index = 1
            })

        end

    end

end

function sProxAlarms:CreateLootbox(args)
    if args.tier ~= 14 then return end -- Not a proximity alarm

    self.alarms[args.uid] = args

end

function sProxAlarms:RemoveLootbox(args)
    if args.tier ~= 14 then return end -- Not a proximity alarm

    self.alarms[args.uid] = nil

end

function sProxAlarms:InsideProximityAlarm(args, player)

    if not args.id then return end

    local alarm = self.alarms[args.id]

    if not alarm then return end

    if count_table(alarm.contents) == 0 then return end -- No batteries

    local exp = player:GetValue("Exp")

    if exp and exp.level == 0 then return end -- Does not work on level 0s

    if player:GetValue("Invisible") then return end

    -- OK now broadcast to owner, if online

    local owner_id = tostring(alarm.stash.owner_id)

    if owner_id == tostring(player:GetSteamId()) then return end -- Don't trigger on owner

    local owner = self.players[owner_id]

    Events:Fire("SendPlayerPersistentMessage", {
        steam_id = owner_id,
        message = string.format("Your proximity alarm detected %s %s", player:GetName(), WorldToMapString(player:GetPosition())),
        color = Color(200, 0, 0)
    })

    if IsValid(owner) then
        Network:Send(owner, "Items/ProximityPlayerDetected", {id = player:GetId(), position = player:GetPosition(), name = player:GetName()})
    end

end

function sProxAlarms:ItemUseCancelUsage(args)

    if self.network_subs[tostring(args.player:GetSteamId())] then
        Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
        self.network_subs[tostring(args.player:GetSteamId())] = nil
    end

    local player_iu = args.player:GetValue("ItemUse")

    if not player_iu or player_iu.item.name ~= "Proximity Alarm" then return end

    Chat:Send(args.player, "Placing proximity alarm failed!", Color.Red)

end

function sProxAlarms:DestroyProx(args, player)
    if not args.id or not self.alarms[args.id] then return end

    local alarm = self.alarms[args.id]

    player = player or args.player

    Events:Fire("SendPlayerPersistentMessage", {
        steam_id = alarm.stash.owner_id,
        message = string.format("Your proximity alarm was destroyed by %s %s", player:GetName(), WorldToMapString(alarm.position)),
        color = Color(200, 0, 0)
    })

    Network:Send(player, "items/ProxExplode", {position = alarm.position})
    Network:SendNearby(player, "items/ProxExplode", {position = alarm.position})

    -- self.recent_ids
    local give_exp = true

    if self.recent_ids[alarm.stash.owner_id] and Server:GetElapsedSeconds() - self.recent_ids[alarm.stash.owner_id] < 60 * 60 then
        give_exp = false
    end

    Events:Fire("items/DestroyProximityAlarm", {
        id = alarm.stash.id,
        player = player,
        give_exp = give_exp
    })

    -- Remove alarm
    self.alarms[args.id] = nil

end

function sProxAlarms:AddAlarm(args)

    -- Create lootbox
    Events:Fire("Items/CreateProximityAlarm", args)

end

function sProxAlarms:SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function sProxAlarms:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

function sProxAlarms:PlaceProx(position, angle, player)

    Events:Fire("Items/PlaceProximityAlarm", {
        position = position,
        angle = angle,
        player = player
    })

    self.recent_ids[tostring(player:GetSteamId())] = Server:GetElapsedSeconds()

end

function sProxAlarms:TryPlaceProx(args, player)

    local player_iu = player:GetValue("ProxUsingItem")

    if not player_iu then return end

    player_iu.delayed = true
    sItemUse:InventoryUseItem(player_iu)

    player:SetValue("ProxUsingItem", nil)

    if self.network_subs[tostring(args.player:GetSteamId())] then
        Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
        self.network_subs[tostring(args.player:GetSteamId())] = nil
    end
    
    local sub
    sub = Network:Subscribe("items/CompleteItemUsage", function(_, _player)
    
        if player ~= _player then return end

        local player_iu = player:GetValue("ItemUse")

        if player_iu.item and ItemsConfig.usables[player_iu.item.name]
            and player_iu.item.name == "Proximity Alarm" then

            Inventory.RemoveItem({
                item = player_iu.item,
                index = player_iu.index,
                player = player
            })

            -- Now actually place the alarm
            self:PlaceProx(args.position, args.angle, player)

        end

        Network:Unsubscribe(sub)
        self.network_subs[tostring(player:GetSteamId())] = nil

    end)

    self.network_subs[tostring(player:GetSteamId())] = sub

end

function sProxAlarms:UseItem(args)

    if args.item.name ~= "Proximity Alarm" then return end
    if args.player:InVehicle() then return end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("ProxUsingItem", args)

    Network:Send(args.player, "items/StartProxPlacement")

end

function sProxAlarms:CancelProxPlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sProxAlarms:FinishProxPlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})

    if player:InVehicle() then
        Chat:Send(player, "Cannot place proximity alarm while in a vehicle!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing proximity alarm failed!", Color.Red)
        return
    end

    if not self.sz_config then
        self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
    end

    local BlacklistedAreas = SharedObject.GetByName("BlacklistedAreas"):GetValues().blacklist

    for _, area in pairs(BlacklistedAreas) do
        if player:GetPosition():Distance(area.pos) < area.size then
            Chat:Send(player, "You cannot place proximity alarms here!", Color.Red)
            return
        end
    end

    if args.model and DisabledPlacementModels[args.model] then
        Chat:Send(player, "Placing proximity alarm failed!", Color.Red)
        return
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if args.position:Distance(self.sz_config.safezone.position) < 2000 then
        Chat:Send(player, "Cannot place proximity alarms while near the safezone!", Color.Red)
        return
    end

    local sub = nil
    sub = Events:Subscribe("IsTooCloseToLootCheck"..tostring(player:GetSteamId()), function(args)
    
        Events:Unsubscribe(sub)
        sub = nil

        if args.too_close then

            Chat:Send(player, "Cannot place proximity alarms too close to loot!", Color.Red)
            return

        end

        self:TryPlaceProx(args, args.player)
        
    end)

    args.player = player
    Events:Fire("CheckIsTooCloseToLoot", args)

end

sProxAlarms = sProxAlarms()