local GRENADE_DEBUG = false

class "Grenades"

Grenades.OverThrowTime = 0.36
Grenades.UnderThrowTime = 0.48

function Sphere(center, radius, nLatitude, nLongitude)
    local vertices = {}
    local fVert    = 2
    local nPitch   = nLongitude + 1
    local pitchInc = (180 / nPitch) * (math.pi / 180)
    local rotInc   = (360 / nLatitude) * (math.pi / 180)

    -- table.insert(vertices, Vertex(Vector3(center.x, center.y + radius, center.z), Color(255, 0, 0, 125)))
    -- table.insert(vertices, Vertex(Vector3(center.x, center.y - radius, center.z), Color(255, 0, 0, 125)))

    local p, s, x, y, z, out

    for p = 1, nPitch do
        out = radius * math.sin(p * pitchInc)

        if out < 0 then
            out = -out
        end

        y = radius * math.cos(p * pitchInc)

        for s = 0, nLatitude do
            x = out * math.cos(s * rotInc)
            z = out * math.sin(s * rotInc)

            table.insert(vertices, Vertex(Vector3(center.x + x, center.y + y, center.z + z), Color(255, 0, 0, 150)))
        end
    end

    return vertices
end

Grenades.DebugModel = Model.Create(Sphere(Vector3.Zero, 1, 32, 32))
Grenades.DebugModel:SetTopology(Topology.LineStrip)

function Grenades:__init()

    self.equipped = true
    self.throw_key = 'V'
    self.throwing = false

    self.grenade_name = "" -- Name of grenade that is current equipped
    self.max_time = 5
    self.max_speed = 25
    self.flashed_time = Grenade.FlashTime
    self.can_use_timer = Timer()

	self.grenades = {}
	self.dummies = {}
	self.thrown = true
	self.thrownType = false
	self.thrownPosition = Vector3()
	self.thrownVelocity = Vector3()
	self.thrownTimer = Timer()
	self.flashedTimer = Timer()

    self.time_to_explode = self.max_time
    self.charge_timer = Timer()
    self.throwing = false
    self.override_animation = false
    LocalPlayer:SetValue("ThrowingGrenade", false)

    self.on_foot_states = {
        [AnimationState.SUprightIdle] = true,
        [AnimationState.SUprightIdleVaried] = true,
        [AnimationState.SUprightRotateCcw] = true,
        [AnimationState.SUprightRotateCcwInterupt] = true,
        [AnimationState.SUprightRotateCw] = true,
        [AnimationState.SUprightRotateCwInterupt] = true,
        [AnimationState.SUprightSprintForwardStop] = true,
        [AnimationState.SUprightStart] = true,
        [AnimationState.SUprightStop] = true,
        [AnimationState.SUprightStrafe] = true,
        [AnimationState.SUprightTurn180] = true,
        [AnimationState.SWalk] = true,
        [AnimationState.SRunStrafeLeftTurn] = true,
        [AnimationState.SRunStrafeLeftTurnInterrupt] = true,
        [AnimationState.SRunStrafeRightTurn] = true,
        [AnimationState.SRunStrafeRightTurnInterrupt] = true,
        [AnimationState.SDash] = true,
        [AnimationState.SDashStop] = true,
        [AnimationState.SDashTurn180] = true,
        [AnimationState.STurningLeft] = true,
        [AnimationState.SParachute] = true,
        [AnimationState.SUprightBasicNavigation] = true,
        [AnimationState.STurningRight] = true
    }

	Events:Subscribe(var("ModuleUnload"):get(), self, self.ModuleUnload)
	Events:Subscribe(var("InputPoll"):get(), self, self.InputPoll)
	Events:Subscribe(var("KeyUp"):get(), self, self.KeyUp)
	Events:Subscribe(var("KeyDown"):get(), self, self.KeyDown)
	Events:Subscribe(var("PostTick"):get(), self, self.PostTick)
	Events:Subscribe(var("Render"):get(), self, self.Render)
	Events:Subscribe(var("GameRender"):get(), self, self.GameRender)
	Events:Subscribe(var("PostRender"):get(), self, self.PostRender)
    Network:Subscribe(var("items/GrenadeTossed"):get(), self, self.GrenadeTossed)
    Network:Subscribe(var("items/ToggleEquippedGrenade"):get(), self, self.ToggleEquippedGrenade)
    Network:Subscribe("items/WarpEffect", self, self.WarpEffect)
end

function Grenades:WarpEffect(args)
    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        effect_id = 250,
        angle = Angle()
    })
end

function Grenades:ToggleEquippedGrenade(args)
    self.equipped = args.equipped

    if self.equipped then
        self.grenade_name = args.name
    else
        self.grenade_name = ""
    end
end

function Grenades:ModuleUnload()
	for k, grenade in pairs(self.grenades) do
		grenade:Remove()
	end

	for k, dummy in pairs(self.dummies) do
        dummy.object:Remove()
        if IsValid(dummy.fx) then dummy.fx:Remove() end
	end
end

function Grenades:InputPoll()
    if Game:GetState() ~= GUIState.Game then return end
	if not self.thrown then
		if not self.thrownTimer then
			self.thrownTimer = Timer()
        end
        
        if not self.override_animation and not LocalPlayer:InVehicle() then

            local base_state = LocalPlayer:GetBaseState()

            if self.on_foot_states[base_state] and base_state ~= AnimationState.SParachute then
                Input:SetValue(Action.TurnLeft, 0)
                Input:SetValue(Action.TurnRight, 0)
                Input:SetValue(Action.LookLeft, 0)
                Input:SetValue(Action.LookUp, 0)
                Input:SetValue(Action.LookRight, 0)
                Input:SetValue(Action.LookDown, 0)

                LocalPlayer:SetAngle(Angle(Camera:GetAngle().yaw, LocalPlayer:GetAngle().pitch, LocalPlayer:GetAngle().roll))
            end

            if self.on_foot_states[base_state] then
                if self.thrownUnder then
                    LocalPlayer:SetLeftArmState(AnimationState.LaSUnderThrowGrenade)
                else
                    LocalPlayer:SetLeftArmState(AnimationState.LaSOverThrowGrenade)
                end
            end

        end
	end
end

function Grenades:KeyUp(args)

    if args.key == string.byte(self.throw_key) and self.equipped and self.throwing then
        self.throwing = false
        self.can_use_timer:Restart()

        if not self.override_animation then
            self:TossGrenade(Grenade.Types[self.grenade_name])
        end
    end

end

function Grenades:KeyDown(args)

    if LocalPlayer:GetValue(var("InSafezone"):get()) or LocalPlayer:InVehicle() then return end
    if self.can_use_timer:GetSeconds() < 0.5 then return end
    if LocalPlayer:GetHealth() <= 0 then return end

    if args.key == string.byte(self.throw_key) and self.equipped and not self.throwing and self.grenade_name:len() > 1 then
        self.time_to_explode = self.max_time
        self.charge_timer = Timer()
        self.throwing = true
        self.can_use_timer:Restart()
        self.override_animation = false
        LocalPlayer:SetValue("ThrowingGrenade", true)
        Network:Send(var("items/StartThrowingGrenade"):get())
    end

end

function Grenades:PostTick(args)
    if not self.thrown and self.grenade_name:len() > 1 then
        
        self.can_use_timer:Restart()
		local position = LocalPlayer:GetBonePosition("ragdoll_LeftForeArm") + LocalPlayer:GetBoneAngle("ragdoll_LeftForeArm") * Grenade.Types[self.grenade_name].offset

        if self.override_animation then
            local grenade = {
				["position"] = position,
				["velocity"] = Vector3.Zero,
                ["fusetime"] = 0,
                ["type"] = self.grenade_name
			}

            Network:Send(var("items/GrenadeTossed"):get(), grenade)
            
            grenade.owner_id = tostring(LocalPlayer:GetSteamId())
			self:GrenadeTossed(grenade)

            self.thrown = true

            return
        end

		self.thrownVelocity = ((Camera:GetAngle() * Angle(0, math.pi * 0.07, 0)) * Vector3.Forward * self.max_speed) * ((Camera:GetAngle().pitch + (math.pi / 2)) / (math.pi / 1.5))
		self.thrownPosition = position

		if self.thrownTimer and self.thrownTimer:GetSeconds() > (self.thrownUnder and Grenades.UnderThrowTime or Grenades.OverThrowTime) then
			local grenade = {
				["position"] = self.thrownPosition,
				["velocity"] = self.thrownVelocity,
                ["fusetime"] = math.max(0, self.max_time - self.charge_timer:GetSeconds()),
                ["type"] = self.grenade_name
			}

            Network:Send(var("items/GrenadeTossed"):get(), grenade)
            grenade.is_mine = true
			self:GrenadeTossed(grenade)

			self.thrown = true
		end
    end
    
    if self.throwing and not self.override_animation then
        self.can_use_timer:Restart()
        local old_time_to_explode = self.time_to_explode
        self.time_to_explode = self.max_time - tonumber(string.format("%.0f", self.charge_timer:GetSeconds()))

        if old_time_to_explode ~= self.time_to_explode and self.grenade_name ~= "Molotov" then
            
            local sound = ClientSound.Create(AssetLocation.Game, {
                bank_id = 11,
                sound_id = 6,
                position = LocalPlayer:GetBonePosition("ragdoll_LeftForeArm"),
                angle = Angle()
            })

            sound:SetParameter(0,0) -- 3.5 total, 
            sound:SetParameter(1,0.75)
            sound:SetParameter(2,0)

            Timer.SetTimeout(200, function()
                sound:Remove()
            end)

        end


        if self.charge_timer:GetSeconds() >= 5 and self.grenade_name ~= "Molotov" then
            self.override_animation = true
            self:TossGrenade(self.type)
        end
    end

	for k, grenade in pairs(self.grenades) do
		grenade:Update()
	end
end

function Grenades:RenderPowerDisplay(args)

    local my_dummy = self.dummies[LocalPlayer:GetId()]
    if not my_dummy or my_dummy.name == "Molotov" then return end

    local size = Vector2(Render.Size.x * 0.1, 45)
    local pos = Vector2(Render.Size.x * 0.5, Render.Size.y - 10 - size.y / 2)

    local num_bars = self.max_time

    for i = 0, num_bars - 1 do
        Render:FillArea(pos - Vector2(size.x * num_bars / 2, size.y / 2) + i * Vector2(size.x + 10, 0), size, Color.Black)

        local color = i < self.time_to_explode and Color.Red or Color.Gray
        Render:FillArea(pos - Vector2(size.x * num_bars / 2, size.y / 2) + i * Vector2(size.x + 10, 0) + Vector2(5,5), size - Vector2(10,10), color)
    end

end

function Grenades:Render(args)
	for player in Client:GetPlayers() do
		self:ApplyDummy(player)
	end

    self:ApplyDummy(LocalPlayer)
    
    if self.equipped and self.throwing then
        self:RenderPowerDisplay(args)
    end

end

function Grenades:GameRender(args)
    for k, grenade in pairs(self.grenades) do

        if (grenade.is_mine or AreFriends(LocalPlayer, grenade.owner_id)) and grenade.detonated and grenade.grenade_type == "Toxic Grenade" then
            local transform = Transform3():Translate(grenade.position):Scale(grenade.radius)

            --Render:SetTransform(transform:Scale(0.1))
            --Grenades.DebugModel:Draw()

            Render:SetTransform(transform)
            Grenades.DebugModel:Draw()
            Render:SetTransform(transform:Rotate(Angle.AngleAxis(math.rad(90), Vector3.Left)))
            Grenades.DebugModel:Draw()

            --Render:SetTransform(transform:Scale(1 / 0.4))
            --Grenades.DebugModel:Draw()

            Render:ResetTransform()
        end
    end

    collectgarbage()
end

function Grenades:PostRender()
	if self.flashedTimer:GetSeconds() < self.flashed_time and self.flashed then
		Render:FillArea(Vector2.Zero, Render.Size, Color(255, 255, 255, self.flashedOpacity * (self.flashed_time - self.flashedTimer:GetSeconds()) / self.flashed_time))
	else
		self.flashed = false
	end
end

function Grenades:ApplyDummy(player)
	local state = player:GetLeftArmState()
	local dummy = self.dummies[player:GetId()]

    if table.find({AnimationState.LaSUnderThrowGrenade, AnimationState.LaSOverThrowGrenade}, state)
    or player:GetValue("ThrowingGrenade") then
    
        local grenade_name = player:GetValue("EquippedGrenade")
        local grenade_data = Grenade.Types[grenade_name]
        if not grenade_data then return end

        if not dummy or dummy.name ~= grenade_name then
            

			dummy = {
                object = ClientStaticObject.Create({
                    model = grenade_data.model,
                    position = Vector3(),
                    angle = Angle()
                    }),
                name = grenade_name
            }

            if grenade_data.extra_effect_id then
                dummy.fx = ClientEffect.Create(AssetLocation.Game, {
                    effect_id = grenade_data.extra_effect_id,
                    position = Vector3(),
                    angle = Angle()
                })
            end
            
			self.dummies[player:GetId()] = dummy
		end

		dummy.object:SetAngle(player:GetBoneAngle("ragdoll_LeftForeArm") * grenade_data.angle)
        dummy.object:SetPosition(player:GetBonePosition("ragdoll_LeftForeArm") + dummy.object:GetAngle() * grenade_data.offset)
        if dummy.fx then
            dummy.fx:SetPosition(dummy.object:GetPosition())
        end

	elseif dummy then
        dummy.object:Remove()
        if IsValid(dummy.fx) then dummy.fx:Remove() end
		self.dummies[player:GetId()] = nil
	end
end

function Grenades:TossGrenade(type)
	if self.thrown and not table.find({AnimationState.LaSUnderThrowGrenade, AnimationState.LaSOverThrowGrenade}, LocalPlayer:GetLeftArmState()) then
		self.thrown = false
		self.thrownUnder = Camera:GetAngle().pitch < -math.pi / 12
		self.thrownType = type
        self.thrownTimer = false
	end
end

function Grenades:GrenadeTossed(args)
    local grenade = Grenade(args)
    self.grenades[grenade.id] = grenade
end

Grenades = Grenades()
