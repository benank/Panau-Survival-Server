class 'cLandclaimObjectPlacer'

function cLandclaimObjectPlacer:__init()

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
    self.default_range = 12
    self.range = self.default_range
    self.snap = false
    self.flat = false
    self.rotation_axis = 1

    self.text_color = Color(211, 167, 167)
    self.text = 
    {
        "Left Click: Place",
        "Right Click: Abort",
        "Mouse Wheel: Rotate",
        "Shift + Mouse Wheel: Rotation speed (%.0f deg)",
        "Q: Rotation Axis (%s)",
        "X: Toggle Snap (%s)",
        "R: Toggle Flat (%s)"
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

    -- Objects with certain collisions that we cannot place on
    self.blacklistedCollisions = 
    {
        ["km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx"] = true, -- Dropbox
        ["38x11.nlz/go231_lod1-a_col.pfx"] = true, -- Barrel stash
        ["f1t16.garbage_can.eez/go225_lod1-a_col.pfx"] = true, -- Garbage stash
        ["areaset03.blz/go161_lod1-a1_dst_col.pfx"] = true, -- Locked stash
        ["samsite.animated.eez/key036sam-d2.lod"] = true, -- Prox alarm
    }

    Events:Subscribe("build/StartLandclaimObjectPlacement", self, self.StartObjectPlacement)
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
function cLandclaimObjectPlacer:StartObjectPlacement(args)

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
        Events:Subscribe("MouseUp", self, self.MouseUp),
        Events:Subscribe("KeyUp", self, self.KeyUp)
    }

    LocalPlayer:SetValue("PlacingLandclaimObject", true)

    self.name = args.name
    self.display_bb = args.display_bb == true
    self.angle_offset = args.angle ~= nil and args.angle or Angle()
    self.offset = args.offset or Vector3()
    self.place_entity = args.place_entity
    self.bb_mod = args.bb_mod or 1
    self.range = args.range or self.default_range

    self.disable_walls = args.disable_walls
    self.disable_ceil = args.disable_ceil

    self.object = ClientStaticObject.Create({
        position = Vector3(),
        angle = self.angle_offset,
        model = args.model
    })

    self.rotation_offset = 
    {
        [1] = 0,
        [2] = 0,
        [3] = 0
    }

    self.placing = true

end

function cLandclaimObjectPlacer:GetBoundingBoxData(object)
    
    local bb1, bb2 = self.object:GetBoundingBox()

    local size = bb2 - bb1

    local offset = bb1 - self.object:GetPosition()

    -- Custom bounding boxes because some are bad
    --if CustomBoundingBoxes[self.object:GetModel()] then
        --local custom_bb = CustomBoundingBoxes[self.object:GetModel()]
        --size = custom_bb.size
        --bb1 = -size / 2
        --bb2 = size / 2
        --offset = bb1 - self.object:GetPosition() - custom_bb.angle * self.angle_offset * (self.offset + custom_bb.offset)
    --end

    return bb1, bb2, size, offset
end

function cLandclaimObjectPlacer:CreateModel()
    
    local color = Color(255, 0, 0, 255)
    local bb1, bb2, size, offset = self:GetBoundingBoxData(self.object)

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

function cLandclaimObjectPlacer:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cLandclaimObjectPlacer:Render(args)

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
            if self.blacklistedCollisions[ray.entity:GetCollision()] then
                can_place_here = false
            end

            self.forward_ray.entity = nil
        end
    end

    local conversion = 1 / 180 * math.pi
    local rotation_offset = Angle(
        self.rotation_offset[1] * conversion,
        self.rotation_offset[2] * conversion,
        self.rotation_offset[3] * conversion
    )
    local ang = Angle.FromVectors(Vector3.Up, ray.normal) * rotation_offset * self.angle_offset

    if self.flat and self.name == "Wall" then
        if self.rotation_axis == 1 then
            ang.roll = 0.157 + math.pi / 2
        else
            ang.roll = 0.157
            --ang.pitch = ang.pitch + math.pi
        end
    end

    self.object:SetAngle(ang)

    for _, data in pairs(BlacklistedAreas) do
        if data.pos:Distance(ray.position) < data.size then
            can_place_here = false
            break
        end
    end

    local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

    for _, area in pairs(ModelChangeAreas) do
        if ray.position:Distance(area.pos) < 10 then
            can_place_here = false
            break
        end
    end

    if in_range then
        if self.snap and IsValid(self.entity) and self.name == "Wall" then -- Snapping only for walls
            self:Snap(ang)
        else
            self.object:SetPosition(ray.position + ang * self.offset)
        end
    else
        self.object:SetPosition(Vector3())
    end

    local angle = self.object:GetAngle()
    local pitch = math.abs(angle.pitch)
    local roll = math.abs(angle.roll)

    if self.disable_walls and (pitch > math.pi / 6 or roll > math.pi / 6) then
        can_place_here = false
    elseif self.disable_ceil and (pitch > math.pi * 0.6 or roll > math.pi * 0.6) then
        can_place_here = false
    end

    -- Move CanBuildInLandclaim to OnPlace check if it gets too laggy
    can_place_here = self:CheckBoundingBox() and self:CanBuildInLandclaim() and can_place_here
    can_place_here = can_place_here and self.object:GetPosition().y > LandclaimObjectConfig.min_height and self.object:GetPosition().y < LandclaimObjectConfig.max_height 
    self.can_place_here = can_place_here
    self:RenderText(can_place_here)

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerRender", {
        object = self.object
    })
end

function GetSign(n)
    return n > 0 and 1 or n < 0 and -1 or 0
end

function cLandclaimObjectPlacer:Snap(ang)
    local relative_look_pos = -self.entity:GetAngle() * (self.forward_ray.position - self.entity:GetPosition())

    local ent_bb1, ent_bb2, ent_size, ent_offset = self:GetBoundingBoxData(self.entity)
    local obj_bb1, obj_bb2, obj_size, obj_offset = self:GetBoundingBoxData(self.object)

    if CustomBoundingBoxes[self.object:GetModel()] then
        ent_size = CustomBoundingBoxes[self.object:GetModel()].size
    end

    ent_size = Vector3(3, 0.3, 3)
    local rounded_relative_pos = Vector3()

    if math.abs(relative_look_pos.x) > math.abs(relative_look_pos.y) and math.abs(relative_look_pos.x) > math.abs(relative_look_pos.z) then
        rounded_relative_pos.y = ent_size.x * GetSign(relative_look_pos.x)
    elseif math.abs(relative_look_pos.z) > math.abs(relative_look_pos.x) and math.abs(relative_look_pos.z) > math.abs(relative_look_pos.y) then
        rounded_relative_pos.z = ent_size.z * GetSign(relative_look_pos.z)
    end

    local angle = self.entity:GetAngle()
    local offset = (angle * -self.angle_offset) * rounded_relative_pos
    self.object:SetAngle(self.entity:GetAngle())
    self.object:SetPosition(self.entity:GetPosition() + offset)

end

-- Returns true if the object is within a landclaim that they can build on
function cLandclaimObjectPlacer:CanBuildInLandclaim()
    local all_landclaims = LandclaimManager.landclaims
    local pos = self.object:GetPosition()

    for steam_id, landclaims in pairs(all_landclaims) do
        for id, landclaim in pairs(landclaims) do
            if IsInSquare(landclaim.position, landclaim.size, pos) and landclaim:CanPlayerPlaceObject(LocalPlayer) then
                return true
            end
        end
    end

    return false
end

function cLandclaimObjectPlacer:CheckBoundingBox()

    -- Don't check bounding box for build items because some of them are terrible
    -- if self.vertices then
    --     local angle = self.object:GetAngle()
    --     local object_pos = self.object:GetPosition() + angle * Vector3(0, 0.1, 0)
    --     for i = 1, #self.vertices, 2 do
    --         local p1 = angle * self.vertices[i].position * 0.5 * self.bb_mod + object_pos
    --         local p2 = angle * self.vertices[i+1].position * 0.5 * self.bb_mod + object_pos

    --         local diff = p2 - p1
    --         local len = diff:Length()

    --         local ray = Physics:Raycast(p1, diff, 0, len)

    --         if (ray.distance < len and ray.entity) then
    --             return false
    --         end
    --     end
    -- else
    --     return false
    -- end

    return true
end

function cLandclaimObjectPlacer:RenderText(can_place_here)

    local text_size = 18

    local render_position = Render.Size / 2 + Vector2(20, 20)

    for index, text in ipairs(self.text) do
        if index == 1 and not can_place_here then
            self:DrawShadowedText(render_position, "CANNOT PLACE HERE", Color.Red, text_size)
        elseif index == 4 then
            self:DrawShadowedText(render_position, string.format(text, self.rotation_speed), self.text_color, text_size)
        elseif index == 5 then
            self:DrawShadowedText(render_position, string.format(text, self.rotation_axis == 1 and "Horizontal" or "Vertical"), self.text_color, text_size)
        elseif index == 6 then
            if self.name == "Wall" then
                self:DrawShadowedText(render_position, string.format(text, self.snap and "Enabled" or "Disabled"), self.text_color, text_size)
            end
        elseif index == 7 then
            if self.name == "Wall" then
                self:DrawShadowedText(render_position, string.format(text, self.flat and "Enabled" or "Disabled"), self.text_color, text_size)
            end
        else
            self:DrawShadowedText(render_position, string.format(text, self.rotation_speed), self.text_color, text_size)
        end

        render_position = render_position + Vector2(0, Render:GetTextHeight(text) + 4)
    end

end

function cLandclaimObjectPlacer:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cLandclaimObjectPlacer:GameRender(args)
    -- Render bounding box
    if not self.placing then return end
    if not IsValid(self.object) then return end

    if self.model and self.display_bb then
        local t = Transform3():Translate(self.object:GetPosition()):Rotate(self.object:GetAngle()):Rotate(-self.angle_offset)
        Render:SetTransform(t)
        self.model:Draw()
        Render:ResetTransform()
    end

    -- Fire an event in case other modules need to render other things, like a line for claymores
    Events:Fire("ObjectPlacerGameRender", {
        object = self.object
    })
end

function cLandclaimObjectPlacer:MouseScroll(args)
    
    local change = math.ceil(args.delta)

    if not Key:IsDown(VirtualKey.Shift) then
        self.rotation_offset[self.rotation_axis] = self.rotation_offset[self.rotation_axis] + change * self.rotation_speed
    else
        self.rotation_speed = self.rotation_speed + 1 * change
        self.rotation_speed = math.min(90, math.max(0, self.rotation_speed))
    end
end

function cLandclaimObjectPlacer:MouseUp(args)

    if args.button == 1 then
        -- Left click, place object

        if self.can_place_here then
            Events:Fire("build/PlaceLandclaimObject", {
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

        Events:Fire("build/CancelLandclaimObjectPlacement", {
            model = self.object:GetModel()
        })
        self:StopObjectPlacement()

    end

end

function cLandclaimObjectPlacer:KeyUp(args)

    if args.key == string.byte("Q") then
        self.rotation_axis = self.rotation_axis == 1 and 3 or 1
    elseif args.key == string.byte("X") then
        self.snap = not self.snap
    elseif args.key == string.byte("R") then
        self.flat = not self.flat
    end

end

function cLandclaimObjectPlacer:StopObjectPlacement(module_unload)
    if IsValid(self.object) then
        self.object:Remove()
    end

    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
    end

    if not module_unload then
        LocalPlayer:SetValue("PlacingLandclaimObject", false)
    end
    self.placing = false
    self.subs = {}
    self.model = nil
    self.vertices = nil
end

function cLandclaimObjectPlacer:ModuleUnload()
    self:StopObjectPlacement(true)
end


cLandclaimObjectPlacer = cLandclaimObjectPlacer()