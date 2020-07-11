class 'cVehicleManager'

function cVehicleManager:__init()

    self.owned_vehicles = {} -- My owned vehicles
    self.in_gas_station = false

    self.vehicle_health_display_timer = Timer()

    self.text = 
    {
        size = 17,
        color = Color.White,
        locked_color = Color(214,30,30),
        unlocked_color = Color(30,214,30),
        shadow_adj = Vector2(1, 1),
        offset = Vector2(25,0)
    }

    self.block_actions = 
    {
        [Action.UseItem] = true,
        --[Action.ExitVehicle] = true,
        [Action.GuiPDAToggleAOI] = true,
        [Action.PickupWithLeftHand] = true,
        [Action.PickupWithRightHand] = true,
        [Action.ActivateBlackMarketBeacon] = true,
        [Action.EnterVehicle] = true,
        [Action.StuntposEnterVehicle] = true
    }

    Events:Fire(var("Vehicles/ResetVehiclesMenu"):get())

    Events:Subscribe(var("Vehicles/SpawnVehicle"):get(), self, self.SpawnVehicle)
    Events:Subscribe(var("Vehicles/DeleteVehicle"):get(), self, self.DeleteVehicle)
    Events:Subscribe(var("Vehicles/TransferVehicle"):get(), self, self.TransferVehicle)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Network:Subscribe(var("Vehicles/SyncOwnedVehicles"):get(), self, self.SyncOwnedVehicles)
    Network:Subscribe(var("Vehicles/VehicleGuardActivate"):get(), self, self.VehicleGuardActivate)

end

function cVehicleManager:VehicleGuardActivate(args)
    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = 92
    })
end

function cVehicleManager:TransferVehicle(args)
    Network:Send(var("Vehicles/TransferVehicle"):get(), {id = args.id, vehicle_id = args.vehicle_id})
end

function cVehicleManager:SpawnVehicle(args)
    Network:Send(var("Vehicles/SpawnVehicle"):get(), args)
end

function cVehicleManager:DeleteVehicle(args)
    Network:Send(var("Vehicles/DeleteVehicle"):get(), args)
end

function cVehicleManager:SyncOwnedVehicles(vehicles)
    self.owned_vehicles = vehicles

    Events:Fire(var("Vehicles/OwnedVehiclesUpdate"):get(), vehicles)
end

function cVehicleManager:LocalPlayerInput(args)
    
    if self.block_actions[args.input] and not LocalPlayer:InVehicle() then

        if LocalPlayer:GetValue("LookingAtLootbox") then return false end

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
            local lockpicks = Inventory.GetNumOfItem({item_name = "Lockpick"})

            if not data then return false end

            if closest_vehicle:GetValue("Destroyed") then return false end

            if data.owner_steamid ~= tostring(LocalPlayer:GetSteamId())
            and not AreFriends(LocalPlayer, data.owner_steamid) then 

                local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 10)

                if not ray.entity or ray.entity.__type ~= "Vehicle" or ray.entity ~= closest_vehicle then
                    return false
                end

                if lockpicks < data.cost or (IsValid(closest_vehicle) and count_table(closest_vehicle:GetOccupants()) > 0) then
                    return false
                end
            end

        elseif args.input == Action.UseItem and not LocalPlayer:GetValue("StuntingVehicle") then
            return false -- Block healthpacks
        end

    end

    -- Block health packs
    if args.input == Action.UseItem and not LocalPlayer:InVehicle() and not LocalPlayer:GetValue("StuntingVehicle") then
        local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 7)
        if not IsValid(ray.entity) then
            return false
        end
    end

    -- Plane reverse
    local v = LocalPlayer:GetVehicle()
	if IsValid(v) then
        local forwardvelocity = math.abs((v:GetAngle() * v:GetLinearVelocity()).z)
        local backwardvelocity = -forwardvelocity
        if planes[v:GetModelId()] 
        and args.input == Action.PlaneDecTrust 
        and v:GetDriver() == LocalPlayer 
        and forwardvelocity < 5
        and backwardvelocity > -1.5
        then
            v:SetLinearVelocity(v:GetLinearVelocity() + v:GetAngle() * Vector3.Backward * 0.2)
        end
    end

end

function cVehicleManager:Render(args)

    if LocalPlayer:InVehicle() then
        self:RenderCurrentVehicleData()
        return
    end

    local aim = LocalPlayer:GetAimTarget()

    if aim.entity and aim.entity.__type == "Vehicle" then
        self:RenderVehicleDataClassic(aim.entity)
    end

end

function cVehicleManager:RenderCurrentVehicleData()

    if LocalPlayer:GetValue("InventoryOpen") then return end

    self:DrawCurrentVehicleSpeed()
    self:DrawCurrentVehicleHealth()

end

function cVehicleManager:DrawCurrentVehicleSpeed()

    local v = LocalPlayer:GetVehicle()
    local speed = math.round(-(-v:GetAngle() * v:GetLinearVelocity()).z)
    local text = string.format("%.0f km/h", speed * 3.6)

    if math.abs(speed) < 1 then return end

    local size = Render.Size.y * 0.04
    local margin = Vector2(-10, -10)
    local text_size = Render:GetTextSize(text, size)
    local pos = Vector2(Render.Size.x - text_size.x, Render.Size.y - text_size.y)
    Render:DrawText(pos + margin + Vector2(2,2), text, Color.Black, size)
    Render:DrawText(pos + margin, text, Color.White, size)

end

function cVehicleManager:DrawCurrentVehicleHealth()

    local v = LocalPlayer:GetVehicle()
    self.vehicle_health = v:GetHealth()

    if self.vehicle_health ~= self.last_vehicle_health then
        self.last_vehicle_health = self.vehicle_health
        self.vehicle_health_display_timer:Restart()
    end

    if self.vehicle_health_display_timer:GetSeconds() < 5 then

        -- Render vehicle health
        local text = string.format("%.0f%%", self.vehicle_health * 100)

        local alpha = 255 - 255 * math.min(1, self.vehicle_health_display_timer:GetSeconds() / 5)
        local color = Color.FromHSV(120 * self.vehicle_health, 0.9, 0.9)
        color.a = alpha
        
        local size = Render.Size.y * 0.04
        local margin = Vector2(0, -10)
        local text_size = Render:GetTextSize(text, size)
        local pos = Vector2(Render.Size.x / 2 - text_size.x / 2, Render.Size.y - text_size.y)
        Render:DrawText(pos + margin, text, color, size)

    end

end

function cVehicleManager:InBoundingBox(v)

    local bb1, bb2 = v:GetBoundingBox()
    local local_pos = LocalPlayer:GetPosition()

    if local_pos.x >= bb1.x and local_pos.x <= bb2.x
    and local_pos.y >= bb1.y and local_pos.y <= bb2.y
    and local_pos.z >= bb1.z and local_pos.z <= bb2.z then
        return true
    end

    return local_pos:Distance(v:GetPosition()) < 5

end

function cVehicleManager:RenderVehicleDataClassic(v)

    if v:GetHealth() <= 0 then return end

    local data = v:GetValue("VehicleData")
    if not data then return end

    local pos = v:GetPosition() + Vector3(0,1,0)
    
    if not self:InBoundingBox(v) then return end

    if v:GetValue("Destroyed") then return end

    local color = self.text.color
    local circle_color = self.text.locked_color

    local friendly_vehicle = tostring(data.owner_steamid) == tostring(LocalPlayer:GetSteamId()) or AreFriends(LocalPlayer, data.owner_steamid)
    
    if friendly_vehicle then
        circle_color = self.text.unlocked_color
    end

    local vehicle_name = tostring(v)
    local vehicle_name_height = Render:GetTextHeight(vehicle_name, self.text.size)

    local cost_str = string.format("Cost: %d Lockpicks", data.cost or "???")
    local cost_str_height = Render:GetTextHeight(vehicle_name, self.text.size)

    local health_str = string.format("Health: %.0f%%", v:GetHealth() * 100)

    local pos_2d = Render:WorldToScreen(pos)
    
    local t = Transform2():Translate(pos_2d)
    Render:SetTransform(t)

    if friendly_vehicle then
        self:DrawShadowedText(-Vector2(0, vehicle_name_height * 1) + self.text.offset, vehicle_name, self.text.color, self.text.size)
        self:DrawShadowedText(Vector2(0, vehicle_name_height * 0) + self.text.offset, health_str, self.text.color, self.text.size)
    else
        self:DrawShadowedText(-Vector2(0, vehicle_name_height * 1.5) + self.text.offset, vehicle_name, self.text.color, self.text.size)
        self:DrawShadowedText(-Vector2(0, vehicle_name_height * 0.5) + self.text.offset, health_str, self.text.color, self.text.size)
        self:DrawShadowedText(Vector2(0, cost_str_height * 0.5) + self.text.offset, cost_str, self.text.color, self.text.size)
    end

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

        if IsValid(v) then

            local data = v:GetValue("VehicleData")

            if data then
                -- Only allow friends or owner to sync destruction
                if data.owner_steamid == tostring(LocalPlayer:GetSteamId())
                or AreFriends(LocalPlayer, data.owner_steamid) then 

                    if v:GetHealth() <= 0.2 and not v:GetValue("Remove") then
                        Network:Send(var("Vehicles/VehicleDestroyed"):get(), {vehicle = v})
                    end

                end
            end
        end

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

    if LocalPlayer:InVehicle() then
        local v = LocalPlayer:GetVehicle()
        if v:GetDriver() == LocalPlayer then

            local vehicle_pos = v:GetPosition()
            local in_gas_station = false
            local station_index = 0

            for _, pos in pairs(gasStations) do
                if pos:Distance(vehicle_pos) < config.gas_station_radius then
                    in_gas_station = true
                    station_index = _
                end
            end

            if self.in_gas_station and not in_gas_station then
                Network:Send("Vehicles/ExitGasStation")
            elseif not self.in_gas_station and in_gas_station then
                Network:Send("Vehicles/EnterGasStation", {index = station_index})
            end
                
            self.in_gas_station = in_gas_station
        end
    end

end

VehicleManager = cVehicleManager()