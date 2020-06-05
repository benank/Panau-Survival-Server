class 'cVehicleWeaponManager'

function cVehicleWeaponManager:__init()

    self.current_heat = var(0)
    self.max_heat = 100
    self.heat_decay_speed = 10
    self.overheated = false

    self.fire_delays = -- Delays between shots for vehicle weapons
    {
        [WeaponEnum.V_Minigun] = 100,
        [WeaponEnum.V_MachineGun] = 400
    }

    self.fire_delay = Client:GetElapsedSeconds()

    -- Handles the FireVehicleWeapon event and the vehicle weapon heat system

    self.vehicle_events = {} -- Events for when you are in a vehicle

    self.heat_actions = 
    {
        [Action.VehicleFireLeft] = 1,
        [Action.VehicleFireRight] = 0
    }

    self.fire_actions = 
    {
        [Action.VehicleFireLeft] = true,
        [Action.VehicleFireRight] = true,
        [Action.FireLeft] = true,
        [Action.FireRight] = true,
        [Action.McFire] = true
    }

    -- Cooldown for using secondary fire again
    self.secondary_fire_cooldown = 5
    self.secondary_fire_timer = Timer()

    Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
    Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
    Events:Subscribe("SecondTick", self, self.SecondTick)

    if LocalPlayer:InVehicle() or LocalPlayer:GetValue("VehicleMG") then
        self:SubscribeVehicleEvents()
    end

end

function cVehicleWeaponManager:SecondTick(args)

    if LocalPlayer:GetValue("VehicleMG") and count_table(self.vehicle_events) == 0 then
        self:SubscribeVehicleEvents()
    elseif not LocalPlayer:GetValue("VehicleMG") and not LocalPlayer:InVehicle() and count_table(self.vehicle_events) > 0 then
        self:UnsubscribeVehicleEvents()
    end

end

function cVehicleWeaponManager:StopFiringInput()

    local input_event
    input_event = Events:Subscribe("InputPoll", function(args)
        for input, _ in pairs(self.fire_actions) do
            Input:SetValue(input, 0)
        end
        input_event = Events:Unsubscribe(input_event)
    end)

end

function cVehicleWeaponManager:IsValidVehicleWeaponAction(input)

    local is_left = input == Action.VehicleFireLeft or input == Action.FireLeft or input == Action.McFire
    if input == nil then is_left = nil end
    return VehicleWeapons:GetPlayerVehicleWeapon(LocalPlayer, is_left)

end

function cVehicleWeaponManager:LocalPlayerInput(args)

    if self.overheated and self.fire_actions[args.input] then self:StopFiringInput() return false end

    if self.heat_actions[args.input] ~= nil then

        -- Not a valid vehicle weapon
        local weapon = self:IsValidVehicleWeaponAction(args.input)
        if not weapon then return false end

        -- Fire delays for the weapons
        local seconds = Client:GetElapsedSeconds()

        if self.fire_delays[weapon] and seconds - self.fire_delay > self.fire_delays[weapon] then return end
        self.fire_delay = seconds

        local current_heat = self.current_heat:get()
        current_heat = math.min(self.max_heat, current_heat + self.heat_actions[args.input])
        self.current_heat:set(current_heat)

        if current_heat == self.max_heat then
            self.overheated = true
        end

        if args.input == Action.VehicleFireRight then

            if self.secondary_fire_timer:GetSeconds() < self.secondary_fire_cooldown then return false end
            self.secondary_fire_timer:Restart()
        end

        Events:Fire(var("FireVehicleWeapon"):get())

    end

end

function cVehicleWeaponManager:Render(args)

    local current_heat = self.current_heat:get()
    current_heat = math.max(0, current_heat - args.delta * self.heat_decay_speed)
    self.current_heat:set(current_heat)

    -- Overheat resets on heat reaching 0
    self.overheated = self.overheated and current_heat > 0

    if not self:IsValidVehicleWeaponAction() then return end

    if current_heat > 0 then
        local bar_size = Vector2(70, 5)
        local bar_pos = Render.Size / 2 + Vector2(0, 30) - Vector2(bar_size.x / 2, 0)

        local fill_color = self.overheated and Color(200, 0, 0, 200) or Color(200, 200, 200, 200)

        Render:FillArea(bar_pos, bar_size, Color(0, 0, 0, 100))
        Render:FillArea(bar_pos, Vector2(bar_size.x * current_heat / self.max_heat, bar_size.y), fill_color)
    end

    local secondary_fire_time = self.secondary_fire_timer:GetSeconds()

    -- No rockets on this vehicle
    if not self:IsValidVehicleWeaponAction(Action.VehicleFireRight) then return end

    -- Cooldown for rockets
    if secondary_fire_time < self.secondary_fire_cooldown then

        local bar_size = Vector2(70, 3)
        local bar_pos = Render.Size / 2 + Vector2(0, 35) - Vector2(bar_size.x / 2, 0)

        local fill_color = Color(0, 200, 200, 200)

        Render:FillArea(bar_pos, bar_size, Color(0, 0, 0, 100))
        Render:FillArea(bar_pos, Vector2(bar_size.x * (1 - secondary_fire_time / self.secondary_fire_cooldown), bar_size.y), fill_color)

    end

end

function cVehicleWeaponManager:LocalPlayerEnterVehicle(args)
    self:SubscribeVehicleEvents()
end

function cVehicleWeaponManager:LocalPlayerExitVehicle(args)
    self:UnsubscribeVehicleEvents()
end

-- Subscribes to events when you enter a vehicle
function cVehicleWeaponManager:SubscribeVehicleEvents()
    self.vehicle_events = 
    {
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("Render", self, self.Render)
    }
end

function cVehicleWeaponManager:UnsubscribeVehicleEvents()
    for k,v in pairs(self.vehicle_events) do
        Events:Unsubscribe(v)
    end
    self.vehicle_events = {}
end

cVehicleWeaponManager = cVehicleWeaponManager()