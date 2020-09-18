class 'cLandclaimExtensionManager'

function cLandclaimExtensionManager:__init()

    self.cooldown_timer = Timer()
    self.range = 4
    self.activation_key = 'E'

    Events:Subscribe("KeyUp", self, self.KeyUp)
end

function cLandclaimExtensionManager:GetLandclaimObjectFromRaycastEntity(entity)
    if not IsValid(entity) then return end
    if entity.__type ~= "ClientStaticObject" then return end

    return entity:GetValue("LandclaimObject")
end

function cLandclaimExtensionManager:TryToUseExtension()

    if LocalPlayer:GetValue("Loading") then return end
    if cObjectPlacer.placing then return end
    if LocalPlayer:GetValue("InventoryOpen") then return end
    if LocalPlayer:InVehicle() then return end

    -- Get current object that we are looking at
    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)
    local landclaim_object = self:GetLandclaimObjectFromRaycastEntity(ray.entity)
    if not landclaim_object then return end

    if self.cooldown_timer:GetSeconds() < 0.2 then return end
    self.cooldown_timer:Restart()

    self.object = landclaim_object

    if self.object.extension then
        self.object.extension:Activate()
    end

end

function cLandclaimExtensionManager:KeyUp(args)

    if args.key == string.byte(self.activation_key) then
        self:TryToUseExtension()
    end
    
end

cLandclaimExtensionManager = cLandclaimExtensionManager()