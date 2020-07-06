class 'cVehicleWeaponManager'

function cVehicleWeaponManager:__init()

    -- Handles the FireVehicleWeapon event and the vehicle weapon heat system

    self.current_heat = var(0)
    self.max_heat = 100
    self.heat_decay_speed = 10
    self.overheated = false

    self.fire_delays = -- Delays between shots for vehicle weapons
    {
        [WeaponEnum.V_Minigun] = 30,
        [WeaponEnum.V_MachineGun] = 200,
        [WeaponEnum.V_Minigun_Warmup] = 50,
        [WeaponEnum.V_Cannon] = 100,
        [WeaponEnum.V_Cannon_Slow] = 1250,
    }

    self.fire_delay = Timer()

    self.warmup_timer = Timer() -- Timer for guns that warmup like the Winstons Amen minigun
    self.firing = false
    self.last_fire = 0

    -- Handles the FireVehicleWeapon event and the vehicle weapon heat system

    self.vehicle_events = {} -- Events for when you are in a vehicle

    self.heat_amounts = 
    {
        [WeaponEnum.V_Minigun] = 1.5,
        [WeaponEnum.V_MachineGun] = 4,
        [WeaponEnum.V_Minigun_Warmup] = 1.75,
        [WeaponEnum.V_Rockets] = 0,
        [WeaponEnum.V_Cannon] = 4,
        [WeaponEnum.V_Cannon_Slow] = 0,
    }

    self.heat_actions = 
    {
        [Action.VehicleFireLeft] = true,
        [Action.VehicleFireRight] = true
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
    self.secondary_fire_cooldown = 2
    self.secondary_fire_timer = Timer()

    Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
    Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("Render", self, self.Render)

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

function cVehicleWeaponManager:StopFiringInput(only_missiles)

    local fire_actions = only_missiles and {[Action.VehicleFireRight] = true} or self.fire_actions

    local timer = Timer()
    local input_event
    input_event = Events:Subscribe("InputPoll", function(args)
        for input, _ in pairs(self.fire_actions) do
            Input:SetValue(input, 0)
        end

        if timer:GetSeconds() >= 1 then
            input_event = Events:Unsubscribe(input_event)
        end
    end)

end

function cVehicleWeaponManager:IsValidVehicleWeaponAction(input)

    local is_left = input == Action.VehicleFireLeft or input == Action.FireLeft or input == Action.McFire
    if input == nil then is_left = nil end
    return VehicleWeapons:GetPlayerVehicleWeapon(LocalPlayer, is_left)

end

function cVehicleWeaponManager:LocalPlayerInput(args)

    if Game:GetState() ~= GUIState.Game then return end

    if self.overheated and self.fire_actions[args.input] then self:StopFiringInput() return false end
    if self.fire_actions[args.input] and (LocalPlayer:GetValue("InventoryOpen") or LocalPlayer:GetValue("MapOpen")) then 
        self:StopFiringInput() 
        return false
    end

    if self.heat_actions[args.input] ~= nil then

        local v = LocalPlayer:GetVehicle() or LocalPlayer:GetValue("VehicleMG")
        if not IsValid(v) or v:GetValue("DisabledByEMP") then return false end

        if not self.firing then
            self.warmup_timer:Restart()
        end

        self.firing = true
        self.last_fire = Client:GetElapsedSeconds()

        -- Not a valid vehicle weapon
        local weapon = self:IsValidVehicleWeaponAction(args.input)
        if not weapon then return false end

        -- Fire delays for the weapons
        local seconds = Client:GetElapsedSeconds()

        if self.fire_delays[weapon] and self.fire_delay:GetMilliseconds() < self.fire_delays[weapon] then return end
        self.fire_delay:Restart()

        if weapon == WeaponEnum.V_Minigun_Warmup and self.warmup_timer:GetSeconds() < 1 then return end

        local current_heat = tonumber(self.current_heat:get())

        if args.input ~= Action.VehicleFireRight and args.input ~= Action.FireRight then
            current_heat = math.min(self.max_heat, current_heat + self.heat_amounts[weapon])
            self.current_heat:set(current_heat)
        end

        if current_heat == self.max_heat then
            self.overheated = true
        end

        if args.input == Action.VehicleFireRight then

            if self.secondary_fire_timer:GetSeconds() < self.secondary_fire_cooldown then
                self:StopFiringInput(true)
                return false
            end
            self.secondary_fire_timer:Restart()
        end

        Events:Fire(var("FireVehicleWeapon"):get(), {
            weapon_enum = weapon
        })

    end

end

function cVehicleWeaponManager:Render(args)

    local current_heat = self.current_heat:get()
    current_heat = math.max(0, current_heat - args.delta * self.heat_decay_speed)
    self.current_heat:set(current_heat)

    -- Overheat resets on heat reaching 0
    self.overheated = self.overheated and current_heat > 0

    if Client:GetElapsedSeconds() - self.last_fire > 0.050 and self.firing then
        self.firing = false
    end

    if not LocalPlayer:InVehicle() and not LocalPlayer:GetValue("VehicleMG") then return end

    if not self:IsValidVehicleWeaponAction() then return end

    self:DrawWeaponHitHud()

    if current_heat > 0 then
        local bar_size = Vector2(70, 5)
        local bar_pos = Render.Size / 2 + Vector2(0, -50) - Vector2(bar_size.x / 2, 0)

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
        local bar_pos = Render.Size / 2 + Vector2(0, -45) - Vector2(bar_size.x / 2, 0)

        local fill_color = Color(0, 200, 200, 200)

        Render:FillArea(bar_pos, bar_size, Color(0, 0, 0, 100))
        Render:FillArea(bar_pos, Vector2(bar_size.x * (1 - secondary_fire_time / self.secondary_fire_cooldown), bar_size.y), fill_color)

    end

end

function cVehicleWeaponManager:DrawWeaponHitHud(args)

    local weapon = self:IsValidVehicleWeaponAction(Action.VehicleFireLeft) or
    self:IsValidVehicleWeaponAction(Action.VehicleFireRight)

    local bullet_data = cWeaponBulletConfig:GetByWeaponEnum(weapon)

    if not bullet_data or not bullet_data.indicator then
        Game:FireEvent("gui.aim.show")
        return
    end

    Game:FireEvent("gui.aim.hide")

    local v = LocalPlayer:GetVehicle() or LocalPlayer:GetValue("VehicleMG")

    local angle = bullet_data.angle(Camera:GetAngle(), v:GetAngle(), v:GetModelId())
    local ray = Physics:Raycast(LocalPlayer:GetBonePosition(BoneEnum.RightHand), angle * Vector3.Forward, 0, 1000)

    local pos, on_screen = Render:WorldToScreen(ray.position)

    self.aim_pos_2d, self.aim_pos_2d_onscreen = pos, on_screen

    if not on_screen then return end

    local width = 2
    local height = 22

    Render:FillArea(pos - Vector2(width / 2, height / 2), Vector2(width, height), Color.White)
    Render:FillArea(pos - Vector2(height / 2, width / 2), Vector2(height, width), Color.White)

end

function cVehicleWeaponManager:DrawBloom(size, color)
    if not self.aim_pos_2d or not self.aim_pos_2d_onscreen then return end
    Render:DrawCircle(self.aim_pos_2d, size, color)
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
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    }
end

function cVehicleWeaponManager:UnsubscribeVehicleEvents()
    for k,v in pairs(self.vehicle_events) do
        Events:Unsubscribe(v)
    end
    self.vehicle_events = {}
    Game:FireEvent("gui.aim.show")
end

cVehicleWeaponManager = cVehicleWeaponManager()