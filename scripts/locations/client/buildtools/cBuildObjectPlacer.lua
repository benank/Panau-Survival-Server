class 'cBuildObjectPlacer'

function cBuildObjectPlacer:__init()

    self.placing = false
    self.rotation_speed = 15
    self.display_bb = false
    self.angle_offset = Angle()
    self.rotation_offset = 
    {
        [1] = 0,
        [2] = 0,
        [3] = 0
    }
    self.range = 1000

    self.rotation_axis = 1

    self.text_color = Color(211, 167, 167)
    self.text = 
    {
        "Left Click: Place",
        "Right Click: Abort",
        "Mouse Wheel: Rotate",
        "R: Change Rotation Axis (Axis: %d)",
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
function cBuildObjectPlacer:StartObjectPlacement(args)

    assert(type(args.model) == "string", "args.model expected to be a string")

    if not LocalPlayer:GetValue("Build_Location") then
        Chat:Print("You must be building at a location to spawn objects!", Color.Red)
        return
    end

    if self.placing then
        self:StopObjectPlacement()
    end

    self.subs = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("GameRender", self, self.GameRender),
        Events:Subscribe("MouseScroll", self, self.MouseScroll),
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("MouseUp", self, self.MouseUp),
        Events:Subscribe("KeyUp", self, self.KeyUp)
    }

    self.display_bb = args.display_bb == true
    self.angle_offset = args.angle ~= nil and args.angle or Angle()
    self.offset = args.offset or Vector3()
    self.bb_mod = args.bb_mod or 1
    
    self.object = ClientStaticObject.Create({
        position = Vector3(),
        angle = self.angle_offset,
        model = args.model
    })

    self.rotation_yaw = 0

    self.placing = true

end

function cBuildObjectPlacer:CreateModel()
    
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

function cBuildObjectPlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cBuildObjectPlacer:Render(args)

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

    local conversion = 1 / 180 * math.pi
    local rotation_offset = Angle(
        self.rotation_offset[1] * conversion,
        self.rotation_offset[2] * conversion,
        self.rotation_offset[3] * conversion
    )
    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * rotation_offset * self.angle_offset
    self.object:SetAngle(ang)

    self.object:SetPosition(ray.position + ang * self.offset)

    self.can_place_here = can_place_here
    self:RenderText(can_place_here)

end

function cBuildObjectPlacer:RenderText(can_place_here)

    local text_size = 18

    local render_position = Render.Size / 2 + Vector2(20, 20)

    for index, text in ipairs(self.text) do
        if index == 1 and not can_place_here then
            self:DrawShadowedText(render_position, "CANNOT PLACE HERE", Color.Red, text_size)
        else
            if index == count_table(self.text) then
                self:DrawShadowedText(render_position, string.format(text, self.rotation_speed), self.text_color, text_size)
            elseif index == count_table(self.text) - 1 then
                self:DrawShadowedText(render_position, string.format(text, self.rotation_axis), self.text_color, text_size)
            else
                self:DrawShadowedText(render_position, text, self.text_color, text_size)
            end
        end

        render_position = render_position + Vector2(0, Render:GetTextHeight(text) + 4)
    end

end

function cBuildObjectPlacer:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cBuildObjectPlacer:GameRender(args)
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

function cBuildObjectPlacer:KeyUp(args)

    if args.key == string.byte("R") then

        self.rotation_axis = self.rotation_axis + 1

        if self.rotation_axis > 3 then
            self.rotation_axis = 1
        end

    end

end

function cBuildObjectPlacer:MouseScroll(args)
    
    local change = math.ceil(args.delta)

    if not Key:IsDown(VirtualKey.Shift) then
        self.rotation_offset[self.rotation_axis] = self.rotation_offset[self.rotation_axis] + change * self.rotation_speed
    else
        self.rotation_speed = self.rotation_speed + 1 * change
        self.rotation_speed = math.min(90, math.max(0, self.rotation_speed))
    end
end

function cBuildObjectPlacer:MouseUp(args)

    if args.button == 1 then
        -- Left click, place object

        if self.can_place_here then
            cBuildMode:PlaceObject({
                position = self.object:GetPosition(),
                angle = self.object:GetAngle()
            })
            self:StopObjectPlacement()
        end

    elseif args.button == 2 then 
        -- Right click, cancel placement
        self:StopObjectPlacement()

    end

end

function cBuildObjectPlacer:StopObjectPlacement()
    if IsValid(self.object) then
        self.object:Remove()
    end

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    self.subs = {}
    self.model = nil
    self.vertices = nil
    self.placing = false
end

function cBuildObjectPlacer:ModuleUnload()
    self:StopObjectPlacement()
end