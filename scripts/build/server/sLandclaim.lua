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

-- Returns if the landclaim is valid, aka it hasn't been deleted and hasn't expired yet
-- We do this to sort old landclaims from current, active ones but keep the old ones
-- to persist the objects that were on them
function sLandclaim:IsActive()
    return self.state == LandclaimStateEnum.Active
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
    end

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

    elseif args.name == "Set Spawn" and object.name == "Bed" then
        -- Setting spawn to a bed
        object.custom_data.player_spawns[player_id] = true

        Events:Fire("SetHomePosition", {
            player = player,
            pos = object.position
        })

        self:SyncSmallUpdate({
            type = "bed_update",
            id = object.id,
            player_spawns = object.custom_data.player_spawns
        })

    elseif args.name == "Unset Spawn" and object.name == "Bed" then
        -- Unsetting spawn from a bed
        object.custom_data.player_spawns[player_id] = nil

        Events:Fire("ResetHomePosition", {
            player = player
        })

        self:SyncSmallUpdate({
            type = "bed_update",
            id = object.id,
            player_spawns = object.custom_data.player_spawns
        })

    elseif args.name == "Remove" and self:CanPlayerPlaceObject(player) then
        self:RemoveObject(args, player)
    end

    self:UpdateToDB()

end

function sLandclaim:CanPlayerPlaceObject(player)

    if not self:IsActive() then return end

    if self.access_mode == LandclaimAccessModeEnum.OnlyMe then
        return self.owner_id == tostring(player:GetSteamId())
    elseif self.access_mode == LandclaimAccessModeEnum.Friends then
        return AreFriends(player, self.owner_id)
    elseif self.access_mode == LandclaimAccessModeEnum.Clan then
        -- TODO: add clan check logic here
        return self.owner_id == tostring(player:GetSteamId())
    elseif self.access_mode == LandclaimAccessModeEnum.Everyone then
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
    if not self:CanPlayerPlaceObject(args.player) then return end

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

end

-- Called when a player tries to remove an object in the landclaim
function sLandclaim:RemoveObject(args, player)
    if not self:CanPlayerPlaceObject(player) then return end

    local object = self.objects[args.id]
    if not object then return end

    self.objects[args.id] = nil

    self:UpdateToDB()

    self:SyncSmallUpdate({
        type = "object_remove",
        id = args.id
    })

    local item = CreateItem({name = object.name, amount = 1, durability = object.health})
    local stack = shStack({contents = {item}})

    Events:Fire("Inventory/CreateDropboxExternal", {
        contents = 
        {
            stack:GetSyncObject()
        },
        position = object.position + Vector3(0, 0.15, 0),
        angle = Angle(math.random() * math.pi * 2, 0, 0)
    })

    -- also remove spawns if there are any attached
end

-- Called when an object on the landclaim is damaged
function sLandclaim:DamageObject(args, player)
    local id = args.landclaim_data.id
    local object = self.objects[id]
    if not object then return end

    object:Damage(C4Damage)

    if object.health <= 0 then
        args.id = id
        self:RemoveObject(args, player)
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