class 'cVehicleManager'

function cVehicleManager:__init()

    self.text = 
    {
        size = 17,
        color = Color.White,
        locked_color = Color(214,30,30),
        unlocked_color = Color(30,214,30),
        shadow_adj = Vector2(1, 1),
        offset = Vector2(25,0)
    }

    self.info_circle = CircleBar(Vector2(), self.text.size * 1, 
	{
		[1] = {max_amount = 100, amount = 50, color = self.text.locked_color}
	})


    self.block_actions = 
    {
        [Action.UseItem] = true,
        [Action.ExitVehicle] = true,
        [Action.GuiPDAToggleAOI] = true,
        [Action.PickupWithLeftHand] = true,
        [Action.PickupWithRightHand] = true,
        [Action.ActivateBlackMarketBeacon] = true,
        [Action.EnterVehicle] = true,
        [Action.StuntJump] = true,
        [Action.EnterVehicle] = true,
        [Action.EnterVehicle] = true,
        [Action.EnterVehicle] = true,
        [Action.EnterVehicle] = true,
        [Action.StuntposEnterVehicle] = true
    }

    Events:Subscribe("SecondTick", self, self.SecondTick)

end

function cVehicleManager:LocalPlayerInput(args)

    if self.block_actions[args.input] and not LocalPlayer:InVehicle() then
        local closest_vehicle, closest_dist = nil, 99
        local pos = LocalPlayer:GetPosition()
        for v in Client:GetVehicles() do
            local dist = v:GetPosition():Distance(pos)
            if dist < closest_dist then
                closest_dist = dist
                closest_vehicle = v
            end
        end

        if closest_vehicle then
            local data = closest_vehicle:GetValue("VehicleData")
            local lockpicks = Inventory.GetNumLockpicks()

            -- TODO check if friends
            if data.owner_id ~= tostring(LocalPlayer:GetSteamId().id) then 
                if lockpicks < data.cost or #closest_vehicle:GetOccupants() > 0 then
                    return false
                end
            end
        end

    end

    -- todo block grappling onto motorcycles

    -- Plane reverse
    local v = LocalPlayer:GetVehicle()
	if IsValid(v) then
        local forwardvelocity = math.abs((v:GetAngle() * v:GetLinearVelocity()).z)
        if planes[v:GetModelId()] and args.input == Action.PlaneDecTrust and v:GetDriver() == LocalPlayer and forwardvelocity < 5 then
            v:SetLinearVelocity(v:GetLinearVelocity() + v:GetAngle() * Vector3.Backward * 0.25)
        end
    end

end

function cVehicleManager:Render(args)

    if LocalPlayer:InVehicle() then return end

    local aim = LocalPlayer:GetAimTarget()

    if aim.entity and aim.entity.__type == "Vehicle" then
        self:RenderVehicleDataClassic(aim.entity)
    end

end

function cVehicleManager:RenderVehicleDataMinimal(v)

    local data = v:GetValue("VehicleData")
    if not data then return end

    local pos = v:GetPosition() + Vector3(0,1,0)
    local bb_min, bb_max = v:GetBoundingBox()
    local v_size = bb_min:Distance(bb_max)
    
    if pos:Distance(LocalPlayer:GetPosition()) > v_size then return end

    local color = self.text.color
    local circle_color = self.text.locked_color
    
    if tostring(data.owner_id) == tostring(LocalPlayer:GetSteamId().id) then -- If this player owns it
        circle_color = self.text.unlocked_color
    elseif false then--string.find(tostring(LocalPlayer:GetValue("Friends")), tostring(data.owner_id))false then
        circle_color = self.text.unlocked_color -- Owned by friend
    end

    local cost_str = string.format("%d", data.cost)
    local cost_str_size = Render:GetTextSize(cost_str, self.text.size)

    local lockpicks_str = "LOCKPICKS"
    local lockpicks_size = self.text.size * 0.28
    local lockpicks_str_size = Render:GetTextSize(lockpicks_str, lockpicks_size)

    if self.info_circle.data[1].amount ~= v:GetHealth() * 100 or self.info_circle.data[1].color ~= circle_color then
        self.info_circle.data[1].amount = v:GetHealth() * 100
        self.info_circle.data[1].color = circle_color
        self.info_circle:Update()
    end

    local pos_2d = Render:WorldToScreen(pos)
    
    local t = Transform2():Translate(pos_2d)
    Render:SetTransform(t)

    self.info_circle:Render(args)
    self:DrawShadowedText(-cost_str_size / 2, cost_str, self.text.color, self.text.size)
    self:DrawShadowedText(-lockpicks_str_size / 2 + Vector2(0, cost_str_size.y * 0.55), lockpicks_str, self.text.color, lockpicks_size)

	Render:ResetTransform()

end

function cVehicleManager:RenderVehicleDataClassic(v)

    local data = v:GetValue("VehicleData")
    if not data then return end

    local pos = v:GetPosition() + Vector3(0,1,0)
    
    if pos:Distance(LocalPlayer:GetPosition()) > 5 then return end

    local color = self.text.color
    local circle_color = self.text.locked_color
    
    if tostring(data.owner_id) == tostring(LocalPlayer:GetSteamId().id) then -- If this player owns it
        circle_color = self.text.unlocked_color
    elseif false then--string.find(tostring(LocalPlayer:GetValue("Friends")), tostring(data.owner_id))false then
        circle_color = self.text.unlocked_color -- Owned by friend
    end

    local vehicle_name = tostring(v)
    local vehicle_name_height = Render:GetTextHeight(vehicle_name, self.text.size)

    local cost_str = string.format("Cost: %d Lockpicks", data.cost)
    local cost_str_height = Render:GetTextHeight(vehicle_name, self.text.size)

    local health_str = string.format("Health: %.0f%%", v:GetHealth() * 100)

    local pos_2d = Render:WorldToScreen(pos)
    
    local t = Transform2():Translate(pos_2d)
    Render:SetTransform(t)
    self:DrawShadowedText(-Vector2(0, vehicle_name_height * 1.5) + self.text.offset, vehicle_name, self.text.color, self.text.size)
    self:DrawShadowedText(-Vector2(0, vehicle_name_height * 0.5) + self.text.offset, cost_str, self.text.color, self.text.size)
    self:DrawShadowedText(Vector2(0, cost_str_height * 0.5) + self.text.offset, health_str, self.text.color, self.text.size)

    local circle_size = self.text.size * 3 / 2 * 0.8
    local circle_pos = -Vector2(circle_size * 1.3, 0)
    Render:FillCircle(circle_pos + self.text.offset, circle_size, circle_color)
    Render:DrawCircle(circle_pos + self.text.offset, circle_size, self.text.color)


	Render:ResetTransform()

end

function cVehicleManager:DrawShadowedText(pos, str, color, size)
    Render:DrawText(pos + self.text.shadow_adj, str, Color.Black, size)
    Render:DrawText(pos, str, color, size)
end

function cVehicleManager:SecondTick()

    local near_vehicle = false

    for v in Client:GetVehicles() do
        near_vehicle = true
        break
    end

    if near_vehicle and not self.render and not self.lpi then
        self.render = Events:Subscribe("Render", self, self.Render)
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    elseif not near_vehicle and self.render and self.lpi then
        Events:Unsubscribe(self.render)
        self.render = nil
        Events:Unsubscribe(self.lpi)
        self.lpi = nil
    end

end

VehicleManager = cVehicleManager()