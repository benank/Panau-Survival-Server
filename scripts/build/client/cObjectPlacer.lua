class 'cObjectPlacer'

function cObjectPlacer:__init()

    self.placing = false
    self.rotation_speed = 0.01
    self.display_bb = false
    self.angle_offset = Angle()
    self.rotation_yaw = 0
    self.range = 8

    self.text_color = Color(211, 167, 167)
    self.text = 
    {
        "Left Click: Place",
        "Right Click: Abort",
        "Mouse Wheel: Rotate",
        "Shift + Mouse Wheel: Rotation speed (%.2f deg)"
    }

    Events:Subscribe("build/StartObjectPlacement", self, self.StartObjectPlacement)
end

--[[
    Starts placement of an objects. 

    args (in table):
        model (string): model of the object you are placing

    optional:
        angle (Angle): angle offset of the object
        display_bb (bool): whether or not to display red lines around the object's bounding box

]]
function cObjectPlacer:StartObjectPlacement(args)

    assert(type(args.model) == "string", "args.model expected to be a string")

    if self.placing then
        self:StopObjectPlacement()
    end

    self.subs = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("GameRender", self, self.GameRender),
        Events:Subscribe("MouseScroll", self, self.MouseScroll),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }

    self.display_bb = args.display_bb == true
    self.angle_offset = args.angle ~= nil and args.angle or Angle()

    self.object = ClientStaticObject.Create({
        position = Vector3(),
        angle = Angle(),
        model = args.model
    })

    self.rotation_yaw = 0

    self.placing = true

end

function cObjectPlacer:Render(args)

    if not self.placing then return end
    if not IsValid(self.obj) then return end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)

    local can_place_here = ray.entity and ray.entity.__type ~= "ClientStaticObject"

    self.object:SetPosition(ray.position)
    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(self.rotation_yaw, 0, 0)
    self.object:SetAngle(ang)


    self:RenderText(can_place_here)

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerRender", {
        object = self.object
    })
end

function cObjectPlacer:RenderText(can_place_here)

    local text_size = 14

    local text1 = "Left click: Place"
    local text2 = "Right click"

    local text_height = Render:GetTextHeight()

end

function cObjectPlacer:DrawShadowedText(pos, text, color, number)


end

function cObjectPlacer:GameRender(args)

end

function cObjectPlacer:MouseScroll(args)

end

function cObjectPlacer:MouseUp(args)

end

function cObjectPlacer:StopObjectPlacement()
    if IsValid(self.object) then return end

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    self.subs = {}
end


cObjectPlacer = cObjectPlacer()