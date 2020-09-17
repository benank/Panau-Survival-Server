class 'cLandclaimPlacer'

function cLandclaimPlacer:__init()

    self.placing = false

    self.text_color = Color(211, 167, 167)
    self.text = 
    {
        "Left Click: Place",
        "Right Click: Abort",
        "Size: %.0fm"
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
        [Action.Kick] = true,
        [Action.ExitVehicle] = true
    }

    Events:Subscribe("build/StartPlacingLandclaim", self, self.StartPlacingLandclaim)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

--[[
    Starts placement of a landclaim. 

    args (in table):
        size (string): size of the landclaim

]]
function cLandclaimPlacer:StartPlacingLandclaim(args)

    assert(type(args.size) == "number", "args.size expected to be a number")

    if self.placing then
        self:StopPlacement()
    end

    self.subs = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("GameRender", self, self.GameRender),
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }

    self.delta = 0

    self.size = args.size

    self.placing = true

end

function cLandclaimPlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cLandclaimPlacer:Render(args)

    if not self.placing then return end

    self.position = LocalPlayer:GetPosition()

    local can_place_here = true

    for _, data in pairs(BlacklistedAreas) do
        if data.pos:Distance(self.position) < data.size + self.size then
            can_place_here = false
            break
        end
    end

    if not self.sz_config then
        self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if self.position:Distance(self.sz_config.neutralzone.position) < self.sz_config.neutralzone.radius * 2 then
        can_place_here = false
    end

    -- If it is within the map bounds
    can_place_here = can_place_here and IsInSquare(Vector3(), 32768, self.position)

    self.can_place_here = can_place_here
    self:RenderText(can_place_here)

end

function cLandclaimPlacer:RenderText(can_place_here)

    local text_size = 18

    local render_position = Render.Size / 2 + Vector2(20, 20)

    for index, text in ipairs(self.text) do
        if index == 1 and not can_place_here then
            self:DrawShadowedText(render_position, "CANNOT PLACE HERE", Color.Red, text_size)
        else
            self:DrawShadowedText(render_position, string.format(text, self.size), self.text_color, text_size)
        end

        render_position = render_position + Vector2(0, Render:GetTextHeight(text) + 4)
    end

end

function cLandclaimPlacer:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cLandclaimPlacer:GameRender(args)
    -- Render bounding box
    if not self.placing then return end
    if not self.position then return end

    self.delta = args.delta + self.delta
    self:RenderLandClaimBorder(self.position, self.size, self.delta)

end

function cLandclaimPlacer:RenderLandClaimBorder(position, size, delta)
    for i = 1, 25 do

        -- draw border lines
        local pos = Vector3(position.x, Camera:GetPosition().y, position.z)
        local t = Transform3():Translate(pos)

        for j = 1, 4 do

            t = t:Rotate(Angle(math.pi / 2, 0, 0))
            Render:SetTransform(t)

            Render:FillArea(Vector3(-size / 2, i * 3 + (delta % 3) - 25, size / 2), Vector3(size, 0.5, 0), Color(0, 255, 0, 100))

        end

    end
end

function cLandclaimPlacer:MouseUp(args)

    if args.button == 1 then
        -- Left click, place object

        if self.can_place_here then
            Network:Send("build/PlaceLandclaim", {
                position = self.position
            })
            self:StopPlacement()
        end

    elseif args.button == 2 then 
        -- Right click, cancel placement

        Events:Fire("build/CancelLandclaimPlacement")
        self:StopPlacement()

    end

end

function cLandclaimPlacer:StopPlacement()

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    self.placing = false
    self.subs = {}
    self.model = nil
    self.vertices = nil
end

function cLandclaimPlacer:ModuleUnload()
    self:StopPlacement()
end


cLandclaimPlacer = cLandclaimPlacer()