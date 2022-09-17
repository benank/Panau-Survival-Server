class 'cGarageDoorExtension'

-- Door extension for cLandclaimObjects that allows for opening/closing
function cGarageDoorExtension:__init(object)
    self.object = object
    self.base_angle = self.object.angle
end

function cGarageDoorExtension:CanPlayerOpenDoor(player)
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

function cGarageDoorExtension:GetAngle()
    return self.object.custom_data.open and Angle(0, 0, math.pi / 2) or Angle()
end

-- Adjust door angle upon streaming in
function cGarageDoorExtension:StreamIn()
    self:Create(true)
    self:UpdateDoorAngle()
    self:UpdateToExternalModules()
end

function cGarageDoorExtension:StreamOut()
    self:Create(false)
    self:UpdateToExternalModules()
end

function cGarageDoorExtension:UpdateToExternalModules()
end

function cGarageDoorExtension:Create(streamed_in)
    self:Remove()
    self:UpdateDoorAngle()
end

function cGarageDoorExtension:Remove()
end

function cGarageDoorExtension:UpdateDoorAngle()
    self.object.object:SetAngle(self.base_angle * self:GetAngle())
end

function cGarageDoorExtension:StateUpdated()
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

function cGarageDoorExtension:Activate()
    if not self:CanPlayerOpenDoor(LocalPlayer) then return end
    Network:Send("build/ActivateDoor", 
        {id = self.object.id, landclaim_id = self.object.landclaim.id, landclaim_owner_id = self.object.landclaim.owner_id})
end