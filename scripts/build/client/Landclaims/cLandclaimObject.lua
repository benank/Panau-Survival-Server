class 'cLandclaimObject'

-- Data container for objects within landclaims
function cLandclaimObject:__init(args)

    self.id = args.id -- Unique object id per claim, changes every reload
    self.owner_id = args.owner_id
    self.owner_name = args.owner_name
    self.name = args.name
    self.position = args.position
    self.angle = args.angle
    self.health = args.health
    self.max_health = args.health -- Store max health for displaying HP
    self.custom_data = args.custom_data
    self.extension = self:GetExtension()
    self.spawned = false
    self.has_collision = false
    self.landclaim = args.landclaim
    self.collision_range = LandclaimObjectCollisionRanges[self.name] or 100

end

-- Creates the ClientStaticObject in the world
function cLandclaimObject:Create(no_collision)
    if self.object then return end -- IsValid will fail if it is too far away

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = self:GetModel(),
        collision = no_collision and "" or self:GetCollision()
    })
    self.object:SetValue("LandclaimObject", self)
    self.spawned = true
    self.has_collision = not no_collision
    
    local event = self.has_collision and "build/SpawnObject" or "build/DespawnObject"
    Events:Fire(event, {
        landclaim_id = self.landclaim.id,
        landclaim_owner_id = self.landclaim.owner_id,
        id = self.id,
        cso_id = self.object:GetId(),
        model = self.object:GetModel()
    })

    if self.extension then
        if self.has_collision then
            self.extension:StreamIn()
        else
            self.extension:StreamOut()
        end
    end
end

function cLandclaimObject:CanPlayerRemoveObject(player)
    local steam_id = tostring(player:GetSteamId())
    return self.landclaim.owner_id == steam_id or self.owner_id == steam_id
end

-- Destroys the ClientStaticObject in the world
function cLandclaimObject:Remove()
    if not self.object then return end -- IsValid will fail if it is too far away
    
    self.object = self.object:Remove()
    self.spawned = false
    
    if self.extension then
        self.extension:Remove()
    end
end

function cLandclaimObject:IsInCollisionRange(pos)
    return self.position:Distance(pos) < self.collision_range
end

-- Destroys the current ClientStaticObject and replaces it with one that has/does not have collision
function cLandclaimObject:ToggleCollision(enabled)
    if self.has_collision == enabled then return end
    self:Remove()
    self:Create(not enabled)
end

function cLandclaimObject:GetModel()
    return BuildObjects[self.name].model
end

function cLandclaimObject:GetCollision()
    return BuildObjects[self.name].collision
end

function cLandclaimObject:GetExtension()

    if self.name == "Door" then
        return cDoorExtension(self)
    elseif self.name == "Light" then
        return cLightExtension(self)
    elseif self.name == "Jump Pad" then
        return cJumpPadExtension(self)
    elseif self.name == "Christmas Tree" then
        return cChristmasTreeExtension(self)
    elseif self.name == "Sign" then
        return cSignExtension(self)
    end

end