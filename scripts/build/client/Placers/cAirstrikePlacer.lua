class 'cAirstrikePlacer'

function cAirstrikePlacer:__init()

    self.placing = false
    self.range = 1000

    self.text_color = Color(211, 167, 167)
    self.text = 
    {
        "Distance: %.0fm",
        "Left Click: Request",
        "Right Click: Abort"
    }

    self.indicator_color = Color(200, 0, 0, 100)

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

    Events:Subscribe("build/StartAirstrikePlacement", self, self.StartAirstrikePlacement)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

--[[
    Starts placement of an Airstrike. 

    args (in table):
        radius (number): radius of the airstrike

]]
function cAirstrikePlacer:StartAirstrikePlacement(args)

    assert(type(args.radius) == "number", "args.radius expected to be a number")

    if self.placing then
        self:StopPlacement()
    end

    self.radius = args.radius

    self.subs = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("GameRender", self, self.GameRender),
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }

    self.placing = true

end

function cAirstrikePlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cAirstrikePlacer:Render(args)

    if not self.placing then return end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)
    ray.position = ray.position + Vector3.Up * 1
    
    -- Make it appear on top of the ocean
    if ray.position.y <= 200 then
        local pos = Camera:GetPosition()
        while pos.y > 200 do
            pos = pos + Camera:GetAngle() * Vector3.Forward * 3
        end
        pos.y = 201
        ray.position = pos
        ray.distance = ray.position:Distance(Camera:GetPosition())
    end

    self.forward_ray = ray

    local in_range = ray.distance < self.range
    local can_place_here = in_range

    --local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(math.pi, 0, 0)
    --self.angle = ang

    --[[for _, data in pairs(BlacklistedAreas) do
        if data.pos:Distance(ray.position) < data.size then
            can_place_here = false
        end
    end]]

    self.can_place_here = can_place_here
    self:RenderText(can_place_here)

end

function cAirstrikePlacer:RenderText(can_place_here)

    local text_size = 18

    local render_position = Render.Size / 2 + Vector2(20, 20)

    for index, text in ipairs(self.text) do
        if index == 2 and not can_place_here then
            self:DrawShadowedText(render_position, "CANNOT PLACE HERE", Color.Red, text_size)
        else
            self:DrawShadowedText(render_position, string.format(text, self.forward_ray.distance), self.text_color, text_size)
        end

        render_position = render_position + Vector2(0, Render:GetTextHeight(text) + 4)
    end

end

function cAirstrikePlacer:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cAirstrikePlacer:GameRender(args)
    -- Render bounding box
    if not self.placing then return end
    if not self.forward_ray then return end

    if not self.can_place_here then return end

    local t = Transform3():Translate(self.forward_ray.position):Rotate(Angle(0, math.pi / 2, 0))
    Render:SetTransform(t)
    Render:FillCircle(Vector3(), self.radius, self.indicator_color)
    Render:ResetTransform()

end

function cAirstrikePlacer:MouseUp(args)

    if args.button == 1 then
        -- Left click, place object

        if self.can_place_here then
            Events:Fire("build/PlaceAirstrike", {
                position = self.forward_ray.position
            })
            self:StopPlacement()
        end

    elseif args.button == 2 then 
        -- Right click, cancel placement

        Events:Fire("build/CancelAirstrikePlacement")
        self:StopPlacement()

    end

end

function cAirstrikePlacer:StopPlacement()

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    self.subs = {}
end

function cAirstrikePlacer:ModuleUnload()
    self:StopPlacement()
end


cAirstrikePlacer = cAirstrikePlacer()