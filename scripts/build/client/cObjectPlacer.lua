class 'cObjectPlacer'

function cObjectPlacer:__init()

    self.placing = false
    self.rotation_speed = 15
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
        "Shift + Mouse Wheel: Rotation speed (%.0f deg)"
    }

    self.subs = {}

    self.blockedActions = {
        [Action.FireLeft] = true,
        [Action.FireRight] = true,
        [Action.McFire] = true,
        [Action.HeliTurnRight] = true,
        [Action.HeliTurnLeft] = true,
        [Action.VehicleFireLeft] = true,
        [Action.ThrowGrenade] = true,
        [Action.VehicleFireRight] = true,
        [Action.Reverse] = true,
        [Action.UseItem] = true,
        [Action.GuiPDAToggleAOI] = true,
        [Action.GrapplingAction] = true,
        [Action.PickupWithLeftHand] = true,
        [Action.PickupWithRightHand] = true,
        [Action.ActivateBlackMarketBeacon] = true,
        [Action.GuiPDAZoomOut] = true,
        [Action.GuiPDAZoomIn] = true,
        [Action.NextWeapon] = true,
        [Action.PrevWeapon] = true,
        [Action.ExitVehicle] = true
    }

    Events:Subscribe("build/StartObjectPlacement", self, self.StartObjectPlacement)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
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
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }

    self.display_bb = args.display_bb == true
    self.angle_offset = args.angle ~= nil and args.angle or Angle()

    self.object = ClientStaticObject.Create({
        position = Vector3(),
        angle = self.angle_offset,
        model = args.model
    })

    self.rotation_yaw = 0

    self.placing = true

end

function cObjectPlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cObjectPlacer:Render(args)

    if not self.placing then return end
    if not IsValid(self.object) then return end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)

    local can_place_here = ray.distance < self.range

    if ray.entity then
        can_place_here = can_place_here and ray.entity.__type == "ClientStaticObject"
    end

    if can_place_here then
        self.object:SetPosition(ray.position)
    else
        self.object:SetPosition(Vector3())
    end
    
    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(self.rotation_yaw / 180 * math.pi, 0, 0) * self.angle_offset
    self.object:SetAngle(ang)

    self:RenderText(can_place_here)

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerRender", {
        object = self.object
    })
end

function cObjectPlacer:RenderText(can_place_here)

    local text_size = 18

    local render_position = Render.Size / 2 + Vector2(20, 20)

    for index, text in ipairs(self.text) do
        if index == 1 and not can_place_here then
            self:DrawShadowedText(render_position, "CANNOT PLACE HERE", Color.Red, text_size)
        else
            self:DrawShadowedText(render_position, string.format(text, self.rotation_speed), self.text_color, text_size)
        end

        render_position = render_position + Vector2(0, Render:GetTextHeight(text) + 4)
    end

end

function cObjectPlacer:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cObjectPlacer:GameRender(args)
    -- Render bounding box
    if not self.placing then return end
    if not IsValid(self.object) then return end

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerGameRender", {
        object = self.object
    })
end

function cObjectPlacer:MouseScroll(args)
    
    local change = math.ceil(args.delta)

    if not Key:IsDown(VirtualKey.Shift) then
        self.rotation_yaw = self.rotation_yaw + change * self.rotation_speed
    else
        self.rotation_speed = self.rotation_speed + 1 * change
        self.rotation_speed = math.min(90, math.max(0, self.rotation_speed))
    end
end

function cObjectPlacer:MouseUp(args)

    if args.button == 1 then
        -- Left click, place object

        Events:Fire("build/PlaceObject", {
            model = self.object:GetModel(),
            position = self.object:GetPosition(),
            angle = self.object:GetAngle()
        })
        self:StopObjectPlacement()

    elseif args.button == 2 then 
        -- Right click, cancel placement

        Events:Fire("build/CancelObjectPlacement", {
            model = self.object:GetModel()
        })
        self:StopObjectPlacement()

    end

end

function cObjectPlacer:StopObjectPlacement()
    if IsValid(self.object) then
        self.object:Remove()
    end

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    self.subs = {}
end

function cObjectPlacer:ModuleUnload()
    self:StopObjectPlacement()
end


cObjectPlacer = cObjectPlacer()