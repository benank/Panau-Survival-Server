class 'cLandclaimObject'

-- Data container for objects within landclaims
function cLandclaimObject:__init(args)

    output_table(args)

    self.id = args.id -- Unique object id per claim, changes every reload
    self.name = args.name
    self.position = args.position
    self.angle = args.angle
    self.health = args.health
    self.max_health = args.health -- Store max health for displaying HP
    self.custom_data = args.custom_data
    self.extensions = self:GetExtensions()
    self.spawned = false
    self.has_collision = false
    self.landclaim = args.landclaim
    self.collision_range = LandclaimObjectCollisionRanges[self.name]

end

-- Creates the ClientStaticObject in the world
function cLandclaimObject:Create(no_collision)
    if IsValid(self.object) then return end
    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = self:GetModel(),
        collision = no_collision and "" or self:GetCollision()
    })
    self.object:SetValue("LandclaimObject", self)
    self.spawned = true
    self.has_collision = not no_collision
end

-- Destroys the ClientStaticObject in the world
function cLandclaimObject:Remove()
    if not IsValid(self.object) then return end
    self.object:Remove()
    self.spawned = false
end

function cLandclaimObject:IsInCollisionRange(pos)
    return self.position:Distance(pos) < self.collision_range
end

-- Destroys the current ClientStaticObject and replaces it with one that has/does not have collision
function cLandclaimObject:ToggleCollision(enabled)
    self:Remove()
    self:Create(not enabled)
end

function cLandclaimObject:GetModel()
    return BuildObjects[self.name].model
end

function cLandclaimObject:GetCollision()
    return BuildObjects[self.name].collision
end

function cLandclaimObject:GetExtensions()
    local extensions = {}

    if self.name == "Door" then
        table.insert(extensions, cDoorExtension(self))
    elseif self.name == "Light" then
        table.insert(extensions, cLightExtension(self))
    elseif self.name == "Bed" then
        table.insert(extensions, cBedExtension(self))
    end

    return extensions
end