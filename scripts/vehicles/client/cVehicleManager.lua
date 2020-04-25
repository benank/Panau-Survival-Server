class 'cVehicleManager'

function cVehicleManager:__init()

    self.owned_vehicles = {} -- My owned vehicles
    self.in_gas_station = false

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

    -- TODO update with levels
    LocalPlayer:SetValue("MaxVehicles", config.player_max_vehicles)

    Events:Fire("Vehicles/ResetVehiclesMenu")

    Events:Subscribe("Vehicles/SpawnVehicle", self, self.SpawnVehicle)
    Events:Subscribe("Vehicles/DeleteVehicle", self, self.DeleteVehicle)
    Events:Subscribe("Vehicles/TransferVehicle", self, self.TransferVehicle)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Network:Subscribe("Vehicles/SyncOwnedVehicles", self, self.SyncOwnedVehicles)
    Network:Subscribe("Vehicles/VehicleGuardActivate", self, self.VehicleGuardActivate)

end

function cVehicleManager:VehicleGuardActivate(args)
    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = 92
    })
end

function cVehicleManager:TransferVehicle(args)
    Network:Send("Vehicles/TransferVehicle", {id = args.id, vehicle_id = args.vehicle_id})
end

function cVehicleManager:SpawnVehicle(args)
    Network:Send("Vehicles/SpawnVehicle", args)
end

function cVehicleManager:DeleteVehicle(args)
    Network:Send("Vehicles/DeleteVehicle", args)
end

function cVehicleManager:SyncOwnedVehicles(vehicles)
    self.owned_vehicles = vehicles

    Events:Fire("Vehicles/OwnedVehiclesUpdate", vehicles)
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

            if data.owner_steamid ~= tostring(LocalPlayer:GetSteamId())
            and not IsAFriend(LocalPlayer, data.owner_steamid) then 
                if lockpicks < data.cost or (IsValid(closest_vehicle) and count_table(closest_vehicle:GetOccupants()) > 0) then
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
        local backwardvelocity = -forwardvelocity
        if planes[v:GetModelId()] 
        and args.input == Action.PlaneDecTrust 
        and v:GetDriver() == LocalPlayer 
        and forwardvelocity < 5
        and backwardvelocity > -2
        then
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

function cVehicleManager:RenderVehicleDataClassic(v)

    if v:GetHealth() <= 0 then return end

    local data = v:GetValue("VehicleData")
    if not data then return end

    local pos = v:GetPosition() + Vector3(0,1,0)
    
    if pos:Distance(LocalPlayer:GetPosition()) > 5 then return end

    local color = self.text.color
    local circle_color = self.text.locked_color

    local friendly_vehicle = tostring(data.owner_steamid) == tostring(LocalPlayer:GetSteamId()) or IsAFriend(LocalPlayer, data.owner_steamid)
    
    if friendly_vehicle then
        circle_color = self.text.unlocked_color
    end

    local vehicle_name = tostring(v)
    local vehicle_name_height = Render:GetTextHeight(vehicle_name, self.text.size)

    local cost_str = string.format("Cost: %d Lockpicks", data.cost)
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

    if LocalPlayer:InVehicle() then
        local v = LocalPlayer:GetVehicle()
        if v:GetDriver() == LocalPlayer then

            local vehicle_pos = v:GetPosition()
            local in_gas_station = false

            for _, pos in pairs(gasStations) do
                if pos:Distance(vehicle_pos) < config.gas_station_radius then
                    in_gas_station = true
                end
            end

            if self.in_gas_station and not in_gas_station then
                Network:Send("Vehicles/ExitGasStation")
            elseif not self.in_gas_station and in_gas_station then
                Network:Send("Vehicles/EnterGasStation")
            end
                
            self.in_gas_station = in_gas_station
        end
    end

end

VehicleManager = cVehicleManager()