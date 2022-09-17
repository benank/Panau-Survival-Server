class 'cStadiumLightExtension'

-- Light extension for cLandclaimObjects that allows for turning off/on
function cStadiumLightExtension:__init(object)
    self.object = object
    self.multiplier = 10
end

function cStadiumLightExtension:StreamIn()
    if IsValid(self.light) then return end
    self.light = ClientLight.Create({
        position = self.object.position + self.object.angle * (Vector3.Up * 12),
        angle = Angle(),
        color = Color.White,
        multiplier = self.object.custom_data.enabled and self.multiplier or 0,
        radius = 100
    })
end

function cStadiumLightExtension:StreamOut()
    if not IsValid(self.light) then return end
    self.light = self.light:Remove()
end

function cStadiumLightExtension:Remove()
    self:StreamOut()
end

function cStadiumLightExtension:StateUpdated(enabled)
    if not self.light then return end
    self.light:SetMultiplier(enabled and self.multiplier or 0)
end

function cStadiumLightExtension:Activate()
    self:StateUpdated(not self.object.custom_data.enabled) -- Local change to activate it instantly before we get the update
    Network:Send("build/ActivateLight", 
        {id = self.object.id, landclaim_id = self.object.landclaim.id, landclaim_owner_id = self.object.landclaim.owner_id})
end