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
function sLandclaim:OnDeleteOrExpire(callback)

    -- Remove all bed spawns
    Thread(function()
        for id, object in pairs(self.objects) do
            if object:RemoveAllBedSpawns() then
                self:SyncSmallUpdate({
                    type = "bed_update",
                    id = object.id,
                    player_spawns = object.custom_data.player_spawns
                })
                Timer.Sleep(1)
            end
        end
        callback()
    end)

end

-- Returns if the landclaim is valid, aka it hasn't been deleted and hasn't expired yet
-- We do this to sort old landclaims from current, active ones but keep the old ones
-- to persist the objects that were on them
function sLandclaim:IsActive()
    return self.state == LandclaimStateEnum.Active
    -- return self.state == LandclaimStateEnum.Active and GetLandclaimDaysTillExpiry(self.expiry_date) > 0
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
        object = self.objects[id]
        
        if object.name == "Bed" then
            for steam_id, _ in pairs(object.custom_data.player_spawns) do
                sLandclaimManager.player_spawns[steam_id] = {id = object.id, landclaim_id = self.id, landclaim_owner_id = self.owner_id}
            end
        elseif object.name == "Teleporter" then
            sLandclaimManager:AddOrUpdateTeleporter(object)
        end

    end

end

function sLandclaim:ToLogString()
    return string.format("LC: %d Owner: %s", self.id, self.owner_id)
end

function sLandclaim:Decay()
    local landclaim_updated = false
    for id, object in pairs(self.objects) do
        local object_data = BuildObjects[object.name]

        if object_data and object_data.unclaimed_decay and object.health > LandclaimObjectConfig.min_object_decay_health then
            object:Damage(LandclaimObjectConfig.decay_per_interval)
            landclaim_updated = true

            if object.health <= 0 then
                self.objects[id] = nil
                object:RemoveAllBedSpawns()

                Events:Fire("Discord", {
                    channel = "Build",
                    content = string.format("Object %s %d decayed and was removed (%s)", 
                        object.name, object.id, self:ToLogString())
                })
            end

            Timer.Sleep(1)
        end
    end
    
    if landclaim_updated then
        self:UpdateToDB()
        self:Sync()
    end
end

-- Called when the landclaim is placed. Looks for objects in expired landclaims within this claim and adds them to the list of objects.
function sLandclaim:ClaimNearbyUnclaimedObjects(player, callback)

    self.objects = {}

    Thread(function()
        for steam_id, player_landclaims in pairs(sLandclaimManager.landclaims) do
            for id, landclaim in pairs(player_landclaims) do
                -- Find inactivate and overlapping landclaims
                local landclaim_updated = false
                if not landclaim:IsActive() and IsInSquare(landclaim.position, landclaim.size * 2 + self.size, self.position) then

                    for _, object in pairs(landclaim.objects) do
                        -- Find objects within the bounds of this landclaim
                        if IsInSquare(object.position, self.size, self.position) and IsValid(player) then
                            local id = self:GetNewUniqueObjectId()
                            object.id = id
                            object.owner_id = self.owner_id
                            object.owner_name = player:GetName()
                            self.objects[id] = object
                            landclaim.objects[_] = nil
                            landclaim_updated = true
                            Timer.Sleep(1)
                        end
                    end

                end

                if landclaim_updated then
                    landclaim:UpdateToDB()
                    landclaim:Sync()
                    Timer.Sleep(1)
                end
            end
        end

        self:UpdateToDB()
        callback()
    end)
end

function sLandclaim:PressBuildObjectMenuButton(args, player)

    if not self:IsActive() then return end

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

function sLandclaim:IsPlayerOwner(player)
    return self.owner_id == tostring(player:GetSteamId())
end

function sLandclaim:CanPlayerAccess(player, access_mode)

    if not self:IsActive() then return end

    local is_owner = self:IsPlayerOwner(player)

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
    if args.position.y < LandclaimObjectConfig.min_height or args.position.y > LandclaimObjectConfig.max_height then return end

    local object = 
    {
        id = self:GetNewUniqueObjectId(),
        name = args.player_iu.item.name,
        model = BuildObjects[args.player_iu.item.name].model,
        collision = BuildObjects[args.player_iu.item.name].collision,
        position = args.position,
        angle = args.angle,
        health = args.player_iu.item.durability,
        owner_id = tostring(args.player:GetSteamId()),
        owner_name = args.player:GetName()
    }

    self.objects[object.id] = sLandclaimObject(object)
    sLandclaimManager:AddOrUpdateTeleporter(self.objects[object.id])

    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "add_object",
        object = self.objects[object.id]:GetSyncObject()
    })

    -- Remove item once it has been placed successfully
    local no_consume = args.player_iu.item.custom_data and tostring(args.player_iu.item.custom_data.no_consume) == "1"
    if not no_consume then
        Inventory.RemoveItem({
            item = args.player_iu.item,
            index = args.player_iu.index,
            player = args.player
        })
    end
    
    Events:Fire("build/ObjectPlaced", {
        player = player,
        owner_id = self.owner_id,
        object_name = object.name,
        object = self.objects[object.id]:GetSyncObject()
    })

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] placed object %s (HP: %d) at pos %s (%s)", 
            args.player:GetName(), tostring(args.player:GetSteamId()), object.name, object.health, object.position, self:ToLogString())
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

function sLandclaim:EditSign(args, player)
    local object = self.objects[args.id]
    if not object then return end

    if object.name ~= "Sign" then return end
    if not self:CanPlayerAccess(player, self.access_mode) then return end
    
    object.custom_data.color = args.color
    object.custom_data.text = tostring(args.text):sub(1, 23)
    
    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "sign",
        id = object.id,
        color = object.custom_data.color,
        text = object.custom_data.text
    })
end

function sLandclaim:EditTeleporterLinkId(args, player)
    local object = self.objects[args.id]
    if not object then return end

    if object.name ~= "Teleporter" then return end
    if not self:IsPlayerOwner(player) then return end
    
    -- Do not allow self-setting
    if args.tp_link_id == object.custom_data.tp_id then
        args.tp_link_id = ""
    end
    
    object.custom_data.tp_link_id = string.trim(tostring(args.tp_link_id or ""):sub(1, 5):upper())
    
    self:UpdateToDB()
    self:SyncSmallUpdate({
        type = "teleporter",
        id = object.id,
        tp_link_id = object.custom_data.tp_link_id
    })
    sLandclaimManager:AddOrUpdateTeleporter(object)
end

function sLandclaim:CanPlayerRemoveObject(object, player)
    local steam_id = tostring(player:GetSteamId())
    return steam_id == self.owner_id or object.owner_id == steam_id
end

-- Called when a player tries to remove an object in the landclaim
function sLandclaim:RemoveObject(args, player)
    if not self:CanPlayerAccess(player, self.access_mode) then return end

    local object = self.objects[args.id]
    if not object then return end

    if not self:CanPlayerRemoveObject(object, player) then return end -- Player did not place object or is not owner

    local item = CreateItem({name = object.name, amount = 1, durability = object.health})
    local stack = shStack({contents = {item}})

    local num_items = Inventory.GetNumOfItem({player = player, item_name = object.name})
    Inventory.AddStack({player = player, stack = stack:GetSyncObject()})

    if num_items == Inventory.GetNumOfItem({player = player, item_name = object.name}) then
        Chat:Send(player, "Failed to remove object! No space in inventory.", Color.Red)
        return
    end

    self.objects[args.id] = nil
    sLandclaimManager:RemoveTeleporter(object)

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

    local mod = 1

    local perks = player:GetValue("Perks")
    local possible_perks = Config.damage_perks[args.type]

    for perk_id, perk_mod_data in pairs(possible_perks) do
        local choice = perks.unlocked_perks[perk_id]
        if perk_mod_data[choice] then
            mod = math.max(mod, perk_mod_data[choice])
        end
    end

    damage = damage * mod
    local is_splash = args.percent_damage ~= nil
    
    if args.percent_damage then
        damage = damage * args.percent_damage
    end

    object:Damage(damage)

    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] damaged object %s %d for %.0f damage using %s (Remaining HP: %.0f) (Splash: %s) (%s)", 
            player:GetName(), tostring(player:GetSteamId()), object.name, object.id, damage, args.type, object.health, tostring(is_splash), self:ToLogString())
    })

    if object.health <= 0 then
        self.objects[id] = nil
        object:RemoveAllBedSpawns()
        Events:Fire("build/ObjectDestroyed", {
            player = player,
            owner_id = self.owner_id,
            object_name = object.name,
            object = object:GetSyncObject()
        })

        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] destroyed object %s %d (Splash: %s) (%s)", 
                player:GetName(), tostring(player:GetSteamId()), object.name, object.id, tostring(is_splash), self:ToLogString())
        })
    end

    self:UpdateToDB()

    self:SyncSmallUpdate({
        type = "object_damaged",
        id = id,
        health = object.health,
        player = player,
        primary = not is_splash
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

-- Called when the landclaim expires
function sLandclaim:Expire()
    self.state = LandclaimStateEnum.Inactive

    self:OnDeleteOrExpire(function()
        self:UpdateToDB()
    end)
    
    self:SyncSmallUpdate({
        type = "state_change",
        state = self.state
    })

    local formatted_date = os.date("%A, %B %d, %Y")
    
    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("Landclaim expired (%s) %s", self:ToLogString(), WorldToMapString(self.position))
    })

    Events:Fire("SendPlayerPersistentMessage", {
        steam_id = self.owner_id,
        message = string.format("Your landclaim %s expired on %s %s", self.name, formatted_date, WorldToMapString(self.position)),
        color = Color(200, 0, 0)
    })
end

-- "Deletes" a landclaim by setting it to be inactive
function sLandclaim:Delete(player)
    self.state = LandclaimStateEnum.Inactive
    self:OnDeleteOrExpire(function()
        self:UpdateToDB()
    end)
    
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