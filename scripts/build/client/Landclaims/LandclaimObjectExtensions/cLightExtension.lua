class 'cLightExtension'

-- Light extension for cLandclaimObjects that allows for turning off/on
function cLightExtension:__init(object)
    self.object = object
    self.multiplier = 4
end

function cLightExtension:StreamIn()
    if IsValid(self.light) then return end
    self.light = ClientLight.Create({
        position = self.object.position + self.object.angle * Vector3.Up,
        angle = Angle(),
        color = Color.White,
        multiplier = self.object.custom_data.enabled and self.multiplier or 0,
        radius = 10
    })
end

function cLightExtension:StreamOut()
    if not IsValid(self.light) then return end
    self.light = self.light:Remove()
end

function cLightExtension:Remove()
    self:StreamOut()
end

function cLightExtension:StateUpdated(enabled)
    self.light:SetMultiplier(enabled and self.multiplier or 0)
end

function cLightExtension:Activate()
    self:StateUpdated(not self.object.custom_data.enabled) -- Local change to activate it instantly before we get the update
    Network:Send("build/ActivateLight", 
        {id = self.object.id, landclaim_id = self.object.landclaim.id, landclaim_owner_id = self.object.landclaim.owner_id})
end