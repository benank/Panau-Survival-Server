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
    Starts placement of an object. 

    args (in table):
        model (string): model of the object you are placing

    optional:
        angle (Angle): angle offset of the object
        display_bb (bool): whether or not to display red lines around the object's bounding box
        disable_walls (bool): whether or not to disable placement on walls
        disable_ceil (bool): whether or not to disable placement on ceilings

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
    self.offset = args.offset or Vector3()
    self.place_entity = args.place_entity
    self.bb_mod = args.bb_mod or 1

    self.disable_walls = args.disable_walls
    self.disable_ceil = args.disable_ceil

    self.object = ClientStaticObject.Create({
        position = Vector3(),
        angle = self.angle_offset,
        model = args.model
    })

    self.rotation_yaw = 0

    self.placing = true

end

function cObjectPlacer:CreateModel()
    
    local bb1, bb2 = self.object:GetBoundingBox()

    local size = bb2 - bb1
    local color = Color(255, 0, 0, 150)

    offset = bb1 - self.object:GetPosition() - self.angle_offset * self.offset

    local vertices = {}

    table.insert(vertices, Vertex(offset, color))
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, 0), color))

    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, 0), color))
    table.insert(vertices, Vertex(offset + Vector3(size.x, size.y, 0), color))

    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, size.z), color))
    table.insert(vertices, Vertex(offset + size, color))

    table.insert(vertices, Vertex(offset + Vector3(0, 0, size.z), color))
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, size.z), color))

    table.insert(vertices, Vertex(offset, color))
    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, 0), color))
    
    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, 0), color))
    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, size.z), color))
    
    table.insert(vertices, Vertex(offset + Vector3(size.x, 0, size.z), color))
    table.insert(vertices, Vertex(offset + Vector3(0, 0, size.z), color))
    
    table.insert(vertices, Vertex(offset + Vector3(0, 0, size.z), color))
    table.insert(vertices, Vertex(offset, color))
    
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, 0), color))
    table.insert(vertices, Vertex(offset + Vector3(size.x, size.y, 0), color))
    
    table.insert(vertices, Vertex(offset + Vector3(size.x, size.y, 0), color))
    table.insert(vertices, Vertex(offset + size, color))
    
    table.insert(vertices, Vertex(offset + size, color))
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, size.z), color))
    
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, size.z), color))
    table.insert(vertices, Vertex(offset + Vector3(0, size.y, 0), color))

    self.model = Model.Create(vertices)
    self.model:SetTopology(Topology.LineList)

    self.vertices = vertices
end

function cObjectPlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cObjectPlacer:Render(args)

    if not self.placing then return end
    if not IsValid(self.object) then return end

    if not self.model then
        self:CreateModel()
    end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)
    self.forward_ray = ray
    self.entity = ray.entity

    local in_range = ray.distance < self.range
    local can_place_here = in_range

    if ray.entity then
        can_place_here = can_place_here and (ray.entity.__type == "ClientStaticObject" or self.place_entity)

        if self.forward_ray.entity.__type == "ClientStaticObject" then
            self.forward_ray.entity = nil
        end
    end

    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(self.rotation_yaw / 180 * math.pi, 0, 0) * self.angle_offset
    self.object:SetAngle(ang)

    local pitch = math.abs(ang.pitch)
    local roll = math.abs(ang.roll)

    if self.disable_walls and (pitch > math.pi / 6 or roll > math.pi / 6) then
        can_place_here = false
    elseif self.disable_ceil and (pitch > math.pi * 0.6 or roll > math.pi * 0.6) then
        can_place_here = false
    end

    for _, data in pairs(BlacklistedAreas) do
        if data.pos:Distance(ray.position) < data.size then
            can_place_here = false
        end
    end

    if in_range then
        self.object:SetPosition(ray.position + ang * self.offset)
    else
        self.object:SetPosition(Vector3())
    end

    can_place_here = self:CheckBoundingBox() and can_place_here
    self.can_place_here = can_place_here
    self:RenderText(can_place_here)

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerRender", {
        object = self.object
    })
end

function cObjectPlacer:CheckBoundingBox()

    if self.vertices then
        local angle = self.object:GetAngle()
        local object_pos = self.object:GetPosition() + angle * Vector3(0, 0.25, 0)
        for i = 1, #self.vertices, 2 do
            local p1 = angle * self.vertices[i].position * 0.7 * self.bb_mod + object_pos
            local p2 = angle * self.vertices[i+1].position * 0.7 * self.bb_mod + object_pos

            local diff = p2 - p1
            local len = diff:Length()

            local ray = Physics:Raycast(p1, diff, 0, len)

            if ray.distance < len or ray.position.y <= 200 then
                return false
            end
        end
    else
        return false
    end

    return true
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

    if self.model and self.display_bb then
        local t = Transform3():Translate(self.object:GetPosition()):Rotate(self.object:GetAngle())
        Render:SetTransform(t)
        self.model:Draw()
        Render:ResetTransform()
    end

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

        if self.can_place_here then
            Events:Fire("build/PlaceObject", {
                model = self.object:GetModel(),
                position = self.object:GetPosition(),
                angle = self.object:GetAngle(),
                forward_ray = self.forward_ray,
                entity = self.entity
            })
            self:StopObjectPlacement()
        end

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
    self.model = nil
    self.vertices = nil
end

function cObjectPlacer:ModuleUnload()
    self:StopObjectPlacement()
end


cObjectPlacer = cObjectPlacer()