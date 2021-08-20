class 'cChristmasTreeExtension'

-- Door extension for cLandclaimObjects that allows for opening/closing
function cChristmasTreeExtension:__init(object)
    self.object = object
    self.timer = Timer()
    self.evenodd = 0
end

-- Adjust door angle upon streaming in
function cChristmasTreeExtension:StreamIn()
    self:Create(true)
    self:UpdateToExternalModules()
end

function cChristmasTreeExtension:StreamOut()
    self:Create(false)
    self:UpdateToExternalModules()
end

function cChristmasTreeExtension:UpdateToExternalModules()
    local event = self.object.has_collision and "build/SpawnObject" or "build/DespawnObject"
    Events:Fire(event, {
        landclaim_id = self.object.landclaim.id,
        landclaim_owner_id = self.object.landclaim.owner_id,
        id = self.object.id,
        cso_id = self.star_object:GetId(),
        model = self.star_object:GetModel()
    })
end

function cChristmasTreeExtension:Render(args)
    if self.timer:GetSeconds() > 1 then
        ClientLight.Play({
            timeout = 1,
            multiplier = 8,
            radius = 10,
            color = self.evenodd % 2 == 0 and Color.Red or Color(0, 255, 0),
            position = self.object.position + Vector3.Up * 2
        })
        self.timer:Restart()
        self.evenodd = self.evenodd + 1
    end
end

function cChristmasTreeExtension:Create(streamed_in)
    self:Remove()
    self.angle = self.object.angle * BuildObjects["Christmas Tree"].star.angle
    self.star_object = ClientStaticObject.Create({
        position = self.object.position + self.angle * BuildObjects["Christmas Tree"].star.offset,
        angle = self.object.angle * BuildObjects["Christmas Tree"].star.angle,
        model = BuildObjects["Christmas Tree"].star.model,
        collision = streamed_in and BuildObjects["Christmas Tree"].star.collision or ""
    })

    if not self.render and streamed_in then
        self.render = Events:Subscribe("Render", self, self.Render)
    elseif self.render and not streamed_in then
        self.render = Events:Unsubscribe(self.render)
    end

    self.star_object:SetValue("LandclaimObject", self.object)
end

function cChristmasTreeExtension:Remove()
    if self.star_object then
        self.star_object = self.star_object:Remove()
    end

    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end
end

function cChristmasTreeExtension:StateUpdated()
    
end

function cChristmasTreeExtension:Activate()
end