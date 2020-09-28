class 'sLandclaim'

function sLandclaim:__init(args)

    self.size = args.size -- Length of one side
    self.position = args.position
    self.owner_id = args.owner_id
    self.name = args.name
    self.expiry_date = args.expiry_date
    self.access_mode = args.access_mode
    self.id = args.id
    self.state = args.state

    self.obj_uid = 0

    self:ParseObjects(args.objects)

end

-- Called when the landclaim is deleted or expires
function sLandclaim:OnDeleteOrExpire()

    -- Remove all bed spawns
    Thread(function()
        for id, object in pairs(self.objects) do
            object:RemoveAllBedSpawns()
            Timer.Sleep(1)
        end
    end)

end

-- Returns if the landclaim is valid, aka it hasn't been deleted and hasn't expired yet
-- We do this to sort old landclaims from current, active ones but keep the old ones
-- to persist the objects that were on them
function sLandclaim:IsActive()
    return self.state == LandclaimStateEnum.Active and GetLandclaimDaysTillExpiry(self.expiry_date) > 0
end

function sLandclaim:GetNewUniqueObjectId()
    self.obj_uid = self.obj_uid + 1
    return self.obj_uid
end

function sLandclaim:ParseObjects(objects)

    self.objects = {}

    if not objects or tostring(objects):len() < 5 then return end

    objects = decode(objects)

    for _, object in pairs(objects) do
        local id = self:GetNewUniqueObjectId()
        object.id = id
        self.objects[id] = sLandclaimObject(object)
        
        if object.name == "Bed" then
            for steam_id, _ in pairs(object.custom_data.player_spawns) do
                sLandclaimManager.player_spawns[steam_id] = {id = object.id, landclaim_id = self.id, landclaim_owner_id = self.owner_id}
            end
        end

    end

end

function sLandclaim:ToLogString()
    return string.format("LC: %d Owner: %s", self.id, self.owner_id)
end

function sLandclaim:PressBuildObjectMenuButton(args, player)

    local object = self.objects[args.id]
    if not object then return end

    if player:GetPosition():Distance(object.position) > 15 then return end

    local player_id = tostring(player:GetSteamId())

    if args.name:find("Access") and object.name == "Door" and self.owner_id == player_id then
        -- Changing door access mode
        if args.name == "Access: Only Me" then
            object.custom_data.access_mode = LandclaimAccessModeEnum.OnlyMe
        elseif args.name == "Access: Friends" then
            object.custom_data.access_mode = LandclaimAccessModeEnum.Friends
        elseif args.name == "Access: Everyone" then
            object.custom_data.access_mode = LandclaimAccessModeEnum.Everyone
        end

        self:SyncSmallUpdate({
            type = "door_access_update",
            id = object.id,
            access_mode = object.custom_data.access_mode
        })
        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] changed door access mod to %s (%s)", player:GetName(), player_id, args.name, self:ToLogString())
        })

    elseif args.name == "Set Spawn" and object.name == "Bed" then
        -- Setting spawn to a bed

        self:UnsetOldSpawn(player_id, sLandclaimManager.player_spawns[player_id])
        
        object.custom_data.player_spawns[player_id] = true
        sLandclaimManager.player_spawns[player_id] = {id = args.id, landclaim_id = self.id, landclaim_owner_id = self.owner_id}

        Events:Fire("SetHomePosition", {
            player = player,
            pos = object.position
        })

        self:SyncSmallUpdate({
            type = "bed_update",
            id = object.id,
            player_spawns = object.custom_data.player_spawns
        })

        Chat:Send(player, "Successfully set spawn point.", Color.Green)

        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] set their spawn to a bed (%s)", player:GetName(), player_id, self:ToLogString())
        })

    elseif args.name == "Unset Spawn" and object.name == "Bed" then
        -- Unsetting spawn from a bed
        object.custom_data.player_spawns[player_id] = nil
        sLandclaimManager.player_spawns[player_id] = nil

        Events:Fire("ResetHomePosition", {
            player = player
        })

        self:SyncSmallUpdate({
            type = "bed_update",
            id = object.id,
            player_spawns = object.custom_data.player_spawns
        })

        Chat:Send(player, "Successfully removed spawn point.", Color.Green)

        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] unset their spawn from a bed (%s)", player:GetName(), player_id, self:ToLogString())
        })


    elseif args.name == "Pick Up" and self:CanPlayerAccess(player, self.access_mode) then
        self:RemoveObject(args, player)
    end

    self:UpdateToDB()

end

-- Unsets a player's previous bed spawn point if it exists
function sLandclaim:UnsetOldSpawn(player_id, old_spawn_data)

    if not old_spawn_data then return end

    local old_spawn = sLandclaimManager.player_spawns[player_id]
    local landclaims = sLandclaimManager.landclaims[old_spawn.landclaim_owner_id]
    if not landclaims then return end

    local landclaim = landclaims[old_spawn.landclaim_id]
    if not landclaim then return end

    local object = landclaim.objects[old_spawn.id]
    if not object then return end

    object.custom_data.player_spawns[player_id] = nil
    landclaim:UpdateToDB()
    
    landclaim:SyncSmallUpdate({
        type = "bed_update",
        id = object.id,
        player_spawns = object.custom_data.player_spawns
    })

end

function sLandclaim:CanPlayerAccess(player, access_mode)

    if not self:IsActive() then return end

    local is_owner = self.owner_id == tostring(player:GetSteamId())

    if access_mode == LandclaimAccessModeEnum.OnlyMe then
        return is_owner
    elseif access_mode == LandclaimAccessModeEnum.Friends then
        return AreFriends(player, self.owner_id) or is_owner
    elseif access_mode == LandclaimAccessModeEnum.Clan then
        -- TODO: add clan check logic here
        return is_owner
    elseif access_mode == LandclaimAccessModeEnum.Everyone then
        return true
    end
end

function sLandclaim:SyncSmallUpdate(args)
    args.landclaim_owner_id = self.owner_id
    args.landclaim_id = self.id
    Network:Broadcast("build/SyncSmallLandclaimUpdate", args)
end

-- Called when a player tries to place an object in the landclaim
function sLandclaim:PlaceObject(args)
    if not self:CanPlayerAccess(args.player, self.access_mode) then return end

    if args.player:GetPosition():Distance(args.position) > 20 then return end

    local object = 
    {
        id = self:GetNewUniqueObjectId(),
        name = args.player_iu.item.name,
        model = BuildObjects[args.player_iu.item.name].model,
        collision = BuildObjects[args.player_iu.item.name].collision,
        position = args.position,
        angle = args.angle,
        health = args.player_iu.item.durability
    }

    self.objects[object.id] = sLandclaimObject(object)

    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "add_object",
        object = self.objects[object.id]:GetSyncObject()
    })

    -- Remove item once it has been placed successfully
    Inventory.RemoveItem({
        item = args.player_iu.item,
        index = args.player_iu.index,
        player = args.player
    })

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] placed object %s at pos %s (%s)", 
            args.player:GetName(), tostring(args.player:GetSteamId()), object.name, object.position, self:ToLogString())
    })
end

function sLandclaim:ChangeAccessMode(access_mode, player)
    if self.owner_id ~= tostring(player:GetSteamId()) then return end
    self.access_mode = access_mode
    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "access_mode",
        access_mode = self.access_mode
    })
    Chat:Send(player, string.format("Access mode changed to %s for %s.", LandclaimAccessModeEnum:GetDescription(self.access_mode), self.name), Color.Green)
    
    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] changed landclaim access mode to %s (%s)", 
            player:GetName(), tostring(player:GetSteamId()), LandclaimAccessModeEnum:GetDescription(self.access_mode), self:ToLogString())
    })
end

function sLandclaim:ActivateLight(args, player)
    local object = self.objects[args.id]
    if not object then return end

    if object.name ~= "Light" then return end
    object.custom_data.enabled = not object.custom_data.enabled
    
    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "light_state",
        id = object.id,
        enabled = object.custom_data.enabled
    })
end

function sLandclaim:ActivateDoor(args, player)
    local object = self.objects[args.id]
    if not object then return end

    if object.name ~= "Door" then return end
    if not self:CanPlayerAccess(player, object.custom_data.access_mode) then return end

    object.custom_data.open = not object.custom_data.open
    
    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "door_state",
        id = object.id,
        open = object.custom_data.open
    })
end

-- Called when a player tries to remove an object in the landclaim
function sLandclaim:RemoveObject(args, player)
    if not self:CanPlayerAccess(player, self.access_mode) then return end

    local object = self.objects[args.id]
    if not object then return end

    local item = CreateItem({name = object.name, amount = 1, durability = object.health})
    local stack = shStack({contents = {item}})

    local num_items = Inventory.GetNumOfItem({player = player, item_name = object.name})
    Inventory.AddStack({player = player, stack = stack:GetSyncObject()})

    if num_items == Inventory.GetNumOfItem({player = player, item_name = object.name}) then
        Chat:Send(player, "Failed to remove object! No space in inventory.", Color.Red)
        return
    end

    self.objects[args.id] = nil

    self:UpdateToDB()

    self:SyncSmallUpdate({
        type = "object_remove",
        id = args.id
    })

    object:RemoveAllBedSpawns()

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] removed object %s (%s)", player:GetName(), tostring(player:GetSteamId()), object.name, self:ToLogString())
    })

end

-- Called when an object on the landclaim is damaged
function sLandclaim:DamageObject(args, player)
    local id = args.landclaim_data.id
    local object = self.objects[id]
    if not object then return end

    if not args.type then return end
    local damage = ExplosiveDamage[args.type]

    if not damage then return end

    -- args.owner_id is valid if player is not

    object:Damage(damage)

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] damaged object %s %d for %.2f damage using %s (%s)", 
            player:GetName(), tostring(player:GetSteamId()), object.name, object.id, damage, args.type, self:ToLogString())
    })

    if object.health <= 0 then
        self.objects[id] = nil
        object:RemoveAllBedSpawns()
        Events:Fire("build/ObjectDestroyed", {
            player = player,
            owner_id = self.owner_id,
            object_name = object.name
        })

        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] destroyed object %s %d (%s)", 
                player:GetName(), tostring(player:GetSteamId()), object.name, object.id, self:ToLogString())
        })
    end

    self:UpdateToDB()

    self:SyncSmallUpdate({
        type = "object_damaged",
        id = id,
        health = object.health,
        player = player
    })

end

-- Called when the owner tries to rename the landclaim
function sLandclaim:Rename(name, player)
    self.name = name
    self:UpdateToDB()
    
    self:SyncSmallUpdate({
        type = "name_change",
        name = self.name
    })

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] renamed landclaim to %s (%s)", player:GetName(), tostring(player:GetSteamId()), name, self:ToLogString())
    })

end

function sLandclaim:UpdateExpiryDate(new_expiry_date)
    self.expiry_date = new_expiry_date
    self:UpdateToDB()
    
    self:SyncSmallUpdate({
        type = "expiry_date_change",
        expiry_date = self.expiry_date
    })
end

-- "Deletes" a landclaim by setting it to be inactive
function sLandclaim:Delete(player)
    self.state = LandclaimStateEnum.Inactive
    self:UpdateToDB()
    
    self:SyncSmallUpdate({
        type = "state_change",
        state = self.state
    })
    
    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] deleted landclaim (%s)", player:GetName(), tostring(player:GetSteamId()), self:ToLogString())
    })
end

-- Should only be used on initial sync, not on update
function sLandclaim:Sync(player)
    if player and not IsValid(player) then return end
    if player then
        Network:Send(player, "build/SyncLandclaim", self:GetSyncObject())
    else
        Network:Broadcast("build/SyncLandclaim", self:GetSyncObject())
    end
end

-- Updates the lanclaim's entry in the database
function sLandclaim:UpdateToDB()
    
    local cmd = SQL:Command("UPDATE landclaims SET name = ?, expiry_date = ?, access_mode = ?, state = ?, objects = ? WHERE steamID = ? AND id = ?")
    cmd:Bind(1, self.name)
    cmd:Bind(2, self.expiry_date)
    cmd:Bind(3, self.access_mode)
    cmd:Bind(4, self.state)
    cmd:Bind(5, self:SerializeObjects())
    cmd:Bind(6, self.owner_id)
    cmd:Bind(7, self.id)
    cmd:Execute()

end

function sLandclaim:SerializeObjects()
    local data = {}
    for id, object in pairs(self.objects) do
        table.insert(data, object:GetSerializable())
    end
    return encode(data)
end

function sLandclaim:GetSyncObjects()
    local data = {}
    for id, object in pairs(self.objects) do
        data[id] = object:GetSyncObject()
    end
    return data
end

function sLandclaim:GetSyncObject()

    return {
        size = self.size,
        position = self.position,
        owner_id = self.owner_id,
        name = self.name,
        expiry_date = self.expiry_date,
        access_mode = self.access_mode,
        objects = self:GetSyncObjects(),
        id = self.id,
        state = self.state
    }

end