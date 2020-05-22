


--Model: samsite.animated.eez/key036sam-d2.lod
--16:51:05 | [info ] | [modelviewer] Collision: samsite.animated.eez/key036sam_lod1-d2_col.pfx

class 'sProxAlarms'

function sProxAlarms:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS proximity_alarms (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, angle VARCHAR, contents BLOB)")

    self.objects = {}

    self.max_items = 1 -- 1 stack of batteries only

    Network:Subscribe("items/CancelProxPlacement", self, self.CancelProxPlacement)
    Network:Subscribe("items/PlaceProx", self, self.FinishProxPlacement)
    Network:Subscribe("items/StepOnProx", self, self.StepOnProx)
    Network:Subscribe("items/DestroyProx", self, self.DestroyProx)
    Network:Subscribe("items/PickupProx", self, self.PickupProx)

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function sProxAlarms:ModuleUnload()

    for id, obj in pairs(self.objects) do
        obj:Remove()
    end

end

function sProxAlarms:ItemExplode(args)

    -- TODO: blowup alarms

end

function sProxAlarms:DestroyProx(args, player)
    if not args.id or not self.objects[args.id] then return end

    local alarm = self.objects[args.id]

    if alarm.exploded then return end

    Network:Send(player, "items/ProxExplode", {position = alarm:GetPosition(), id = alarm.id})
    Network:SendNearby(player, "items/ProxExplode", {position = alarm:GetPosition(), id = alarm.id})

    local cmd = SQL:Command("DELETE FROM proximity_alarms where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove alarm
    local cell = alarm:GetCell()
    self.claymores[args.id] = nil
    alarm:Remove()

end

function sProxAlarms:PickupProx(args, player)
    if not args.id or not self.objects[args.id] then return end

    local alarm = self.objects[args.id]

    if alarm.owner_id ~= tostring(player:GetSteamId()) then return end -- They do not own this alarm

    if alarm.position:Distance(player:GetPosition()) > 5 then return end

    local num_alarms = Inventory.GetNumOfItem({player = player, item_name = "Proximity Alarm"})

    local item = deepcopy(Items_indexed["Proximity Alarm"])
    item.amount = 1

    Inventory.AddItem({
        item = item,
        player = player
    })

    -- If the number of alarms in their inventory did not go up, they did not have room for it
    if num_alarms == Inventory.GetNumOfItem({player = player, item_name = "Proximity Alarm"}) then
        Chat:Send(player, "Failed to pick up alarm because you do not have space for it!", Color.Red)
        return
    end

    local cmd = SQL:Command("DELETE FROM proximity_alarms where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove alarm
    self.objects[args.id] = nil
    alarm:Remove()

end

-- When someone enters the range of the alarm
function sProxAlarms:StepOnProx(args, player)

    if not args.id then return end
    local id = tonumber(args.id)

    local alarm = self.objects[id]
    if not alarm then return end

    -- TODO: send data to player

end

function sProxAlarms:AddAlarm(args)

    -- Create lootbox
    Events:Fire("Items/CreateProximityAlarm", args)

end

-- Load all claymores from DB
function sProxAlarms:LoadAllProx()

    local result = SQL:Query("SELECT * FROM proximity_alarms"):Execute()
    
    if #result > 0 then

        for _, alarm_data in pairs(result) do
            local split = alarm_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            local angle = self:DeserializeAngle(alarm_data.angle)

            self:AddAlarm({
                id = alarm_data.id,
                owner_id = alarm_data.steamID,
                position = pos,
                angle = angle
            })
        end

    end

end

function sProxAlarms:SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function sProxAlarms:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

function sProxAlarms:PlaceProx(position, angle, player)

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO proximity_alarms (steamID, position, angle, contents) VALUES (?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Bind(3, self:SerializeAngle(angle))
    cmd:Bind(4, "")
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM proximity_alarms")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place proximity alarm")
        return
    end
    
    self:AddAlarm({
        id = result[1].id,
        owner_id = steamID,
        position = position,
        angle = angle
    })

end

function sProxAlarms:TryPlaceProx(args, player)

    local player_iu = player:GetValue("ProxUsingItem")

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

    if args.model and DisabledPlacementModels[args.model] then
        Chat:Send(player, "Placing proximity alarm failed!", Color.Red)
        return
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if args.position:Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
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
sProxAlarms:LoadAllProx()