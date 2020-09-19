class 'cDoorExtension'

-- Door extension for cLandclaimObjects that allows for opening/closing
function cDoorExtension:__init(object)
    self.object = object
end

function cDoorExtension:CanPlayerOpenDoor(player)
    local access_mode = self.object.custom_data.access_mode
    local is_owner = self.object.landclaim.owner_id == tostring(player:GetSteamId())

    if access_mode == LandclaimAccessModeEnum.OnlyMe then
        return is_owner
    elseif access_mode == LandclaimAccessModeEnum.Friends then
        return AreFriends(player, self.object.landclaim.owner_id) or is_owner
    elseif access_mode == LandclaimAccessModeEnum.Clan then
        -- TODO: add clan check logic here
        return is_owner
    elseif access_mode == LandclaimAccessModeEnum.Everyone then
        return true
    end
end

function cDoorExtension:GetAngle()
    return self.object.custom_data.open and Angle(math.pi / 2, 0, 0) or Angle()
end

-- Adjust door angle upon streaming in
function cDoorExtension:StreamIn()
    self:Create(true)
    self:UpdateDoorAngle()
    self:UpdateToExternalModules()
end

function cDoorExtension:StreamOut()
    self:Create(false)
    self:UpdateToExternalModules()
end

function cDoorExtension:UpdateToExternalModules()
    local event = self.object.has_collision and "build/SpawnObject" or "build/DespawnObject"
    Events:Fire(event, {
        landclaim_id = self.object.landclaim.id,
        landclaim_owner_id = self.object.landclaim.owner_id,
        id = self.object.id,
        cso_id = self.door_object:GetId()
    })
end

function cDoorExtension:Create(streamed_in)
    self:Remove()
    self.angle = self.object.angle * BuildObjects["Door"].door.angle
    self.door_object = ClientStaticObject.Create({
        position = self.object.position + self.angle * BuildObjects["Door"].door.offset,
        angle = self.object.angle * BuildObjects["Door"].door.angle,
        model = BuildObjects["Door"].door.model,
        collision = streamed_in and BuildObjects["Door"].door.collision or ""
    })
    self.door_object:SetValue("LandclaimObject", self.object)
    self:UpdateDoorAngle()
end

function cDoorExtension:Remove()
    if self.door_object then
        self.door_object = self.door_object:Remove()
    end
end

function cDoorExtension:UpdateDoorAngle()
    if not IsValid(self.door_object) then return end
    self.door_object:SetAngle(self.angle * self:GetAngle())
end

function cDoorExtension:StateUpdated()
    self:UpdateDoorAngle()

    -- Play door sound if we're close
    if Camera:GetPosition():Distance(self.object.position) < 30 then
        local sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 6,
            sound_id = 4,
            position = self.object.position,
            angle = Angle()
        })
        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
        sound:SetParameter(2,-180)
        Timer.SetTimeout(1000, function()
            sound:Remove()
        end)
    end
end

function cDoorExtension:Activate()
    if not self:CanPlayerOpenDoor(LocalPlayer) then return end
    Network:Send("build/ActivateDoor", 
        {id = self.object.id, landclaim_id = self.object.landclaim.id, landclaim_owner_id = self.object.landclaim.owner_id})
end