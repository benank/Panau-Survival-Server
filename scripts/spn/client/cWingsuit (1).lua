class 'Wingsuit'

function Wingsuit:__init()

	self.superman = true -- Enables superman physics (disables custom grapple)
	self.grapple = false -- Enables custom grapple while gliding
	self.rolls = false -- Enables barrel rolls
	
	self.default_speed = 51 -- 51 m/s default
	self.default_vertical_speed = -2.5 -- -7 ms default
	
	self.max_speed = 999999999999999 -- 300 m/s default, for superman mode
	self.min_speed = 1 -- 1 m/s default, for superman mode
	
	self.tether_length = 150 -- meters
	self.yaw_gain = 1.5
	self.yaw = 0
	
	self.speed = self.default_speed
	self.vertical_speed = self.default_vertical_speed
	
	self.blacklist = {
		actions = { -- Actions to block while wingsuit is active
			[Action.LookUp] = true,
			[Action.LookDown] = true,
			[Action.LookLeft] = true,
			[Action.LookRight] = true
		},
		animations = { -- Disallow activation during these base states
			[AnimationState.SDead] = true,
			[AnimationState.SUnfoldParachuteHorizontal] = true,
			[AnimationState.SUnfoldParachuteVertical] = true,
			[AnimationState.SPullOpenParachuteVertical] = true
		}
	}
	
	self.whitelist = { -- Allow instant activation during these base states
		animations = {
			[AnimationState.SSkydive] = true,
			[AnimationState.SParachute] = true
		}
	}
	
	self.timers = {
		grapple = Timer()
	}
	
	self.subs = {}
	
	Events:Subscribe("KeyUp", self, self.Activate)
	Events:Subscribe("ModulesLoad", self, self.AddHelp)
	Events:Subscribe("ModuleUnload", self, self.RemoveHelp)

end

function Wingsuit:Activate(args)

	if args.key == VirtualKey.Shift and not self.subs.camera and LocalPlayer:GetState() == PlayerState.OnFoot then
	
		local bs = LocalPlayer:GetBaseState()
		if self.blacklist.animations[bs] then return end

		if not self.timers.activate or self.timers.activate:GetMilliseconds() > 500 then

			self.timers.activate = Timer()

		elseif self.timers.activate:GetMilliseconds() < 500 then

			self.timers.activate = nil
			
			if self.whitelist.animations[bs] then
				
				self.timers.camera_start = Timer()
				self.speed = self.default_speed
				LocalPlayer:SetBaseState(AnimationState.SSkydive)
				self.subs.wings = Events:Subscribe("GameRender", self, self.DrawWings)
				self.subs.velocity = Events:Subscribe("Render", self, self.SetVelocity)
				self.subs.camera = Events:Subscribe("CalcView", self, self.Camera)
				self.subs.glide = Events:Subscribe("InputPoll", self, self.Glide)
				self.subs.input = Events:Subscribe("LocalPlayerInput", self, self.Input)
				
			elseif self.superman then
		
				local timer = Timer()
				self.timers.camera_start = Timer()
				self.subs.camera = Events:Subscribe("CalcView", self, self.Camera)
				self.subs.input = Events:Subscribe("LocalPlayerInput", self, self.Input)
				self.subs.wings = Events:Subscribe("GameRender", self, self.DrawWings)
				self.subs.delay = Events:Subscribe("PreTick", function()
					LocalPlayer:SetLinearVelocity(LocalPlayer:GetAngle() * Vector3(0, 5, -5))
					if timer:GetMilliseconds() > 1000 then
						Events:Unsubscribe(self.subs.delay)
						self.subs.delay = nil
						self.speed = self.default_speed
						LocalPlayer:SetBaseState(AnimationState.SSkydive)
						self.subs.velocity = Events:Subscribe("Render", self, self.SetVelocity)
					end
				end)

			end
			
		end

	elseif args.key == VirtualKey.Control and self.subs.camera then
	
		if not self.timers.activate or self.timers.activate:GetMilliseconds() > 500 then
			self.timers.activate = Timer()
		elseif self.timers.activate:GetMilliseconds() < 500 then
			local ray = Physics:Raycast(LocalPlayer:GetPosition(), LocalPlayer:GetAngle() * Vector3(0, -1, -1), 0, 50)
			if ray.distance < 50 then
				LocalPlayer:SetBaseState(AnimationState.SFall)
			else
				LocalPlayer:SetBaseState(AnimationState.SSkydive)
			end
			self:Abort()
		end

	end

end

function Wingsuit:DrawWings()

	self.dt = math.abs((Game:GetTime() + 12) % 24 - 12) / 12

	local bones = LocalPlayer:GetBones()
	local color = LocalPlayer:GetColor()
	
	local r = math.lerp(0.1 * color.r, color.r, self.dt)
	local g = math.lerp(0.1 * color.g, color.g, self.dt)
	local b = math.lerp(0.1 * color.b, color.b, self.dt)
	
	color = Color(r, g, b)
	

end

function Wingsuit:SetVelocity()
	
	local bs = LocalPlayer:GetBaseState()

	if bs ~= AnimationState.SSkydive and bs ~= AnimationState.SSkydiveDash then
		self:Abort()
		return
	end
	
	if self.superman then
	
		if Key:IsDown(VirtualKey.Shift) and self.speed < self.max_speed then
			self.speed = self.speed + 1
		elseif Key:IsDown(VirtualKey.Control) and self.speed > self.min_speed then
			self.speed = self.speed - 1
		end
			
		local speed = self.speed - math.sin(LocalPlayer:GetAngle().pitch) * 20
		LocalPlayer:SetLinearVelocity(LocalPlayer:GetAngle() * Vector3(0, 0, -speed))
		
	else
	
		local speed = self.speed - math.sin(LocalPlayer:GetAngle().pitch) * 20
		LocalPlayer:SetLinearVelocity(LocalPlayer:GetAngle() * Vector3(0, 0, -speed) 
			+ Vector3(0, self.vertical_speed, 0))		
	
	end
	
	local speed = LocalPlayer:GetLinearVelocity():Length() * 3.6
	local player_pos = LocalPlayer:GetPosition()
	local altitude = player_pos.y - (math.max(200, Physics:GetTerrainHeight(player_pos)))
	local hud_str = string.format("%i km/h   %i m", speed, altitude)
	local screen_pos = Vector2(0.5 * Render.Width - 0.5 * Render:GetTextWidth(hud_str, TextSize.Large), Render.Height - Render:GetTextHeight(hud_str, TextSize.Large))
	
	Render:DrawText(screen_pos + Vector2(1,1), hud_str, Color.Black, TextSize.Large)
	Render:DrawText(screen_pos, hud_str, Color.White, TextSize.Large)
	
	if not self.rolls or self.subs.grapple then return end
	
	if Input:GetValue(Action.MoveLeft) > 0 then
		if not self.roll_left then
			self.roll_left = true
			if not self.timers.roll_left then
				self.timers.roll_left = Timer()
			elseif self.timers.roll_left:GetMilliseconds() < 500 then
				if not self.subs.roll_left then
					local timer = Timer()
					LocalPlayer:SetBaseState(AnimationState.SSkydiveDash)
					self.subs.roll_left = Events:Subscribe("PreTick", function()
						if timer:GetMilliseconds() > 750 then
							LocalPlayer:SetBaseState(AnimationState.SSkydive)
							Events:Unsubscribe(self.subs.roll_left)
							self.subs.roll_left = nil
						end
					end)
				end
				self.timers.roll_left = nil
			else
				self.timers.roll_left = nil
			end
		end
	else
		self.roll_left = nil
	end
	
	if Input:GetValue(Action.MoveRight) > 0 then
		if not self.roll_right then
			self.roll_right = true
			if not self.timers.roll_right then
				self.timers.roll_right = Timer()
			elseif self.timers.roll_right:GetMilliseconds() < 500 then
				if not self.subs.roll_right then
					local timer = Timer()
					LocalPlayer:SetBaseState(AnimationState.SSkydiveDash)
					self.subs.roll_right = Events:Subscribe("PreTick", function()
						if timer:GetMilliseconds() > 750 then
							LocalPlayer:SetBaseState(AnimationState.SSkydive)
							Events:Unsubscribe(self.subs.roll_right)
							self.subs.roll_right = nil
						end
					end)
				end
				self.timers.roll_right = nil
			else
				self.timers.roll_right = nil
			end
		end
	else
		self.roll_right = nil
	end

end

function Wingsuit:Glide()
	
	if self.superman then return end

	if not self.hit then

		if Input:GetValue(Action.MoveBackward) > 0 and LocalPlayer:GetAngle().pitch > 0 then
			Input:SetValue(Action.MoveBackward, 0)
		end
	
	else
	
		Input:SetValue(Action.MoveBackward, 1)
		
		if self.yaw < 0 then
			Input:SetValue(Action.MoveLeft, -self.yaw_gain * self.yaw)
		elseif self.yaw > 0 then
			Input:SetValue(Action.MoveRight, self.yaw_gain * self.yaw)
		end

	end

end

function Wingsuit:Input(args)

	if Game:GetState() ~= GUIState.Game then return end
	
	if not self.superman and self.grapple and args.input == Action.FireGrapple then
	
		if self.subs.grapple or self.subs.roll_left or self.subs.roll_right or self.timers.grapple:GetMilliseconds() < 500 then return false end
		
		local angle = LocalPlayer:GetAngle()
		
		if angle.pitch < -0.2 * math.pi then return false end
			
		LocalPlayer:SetLeftArmState(399)
		
		self.timers.grapple = Timer()
		local direction = Angle(angle.yaw, 0, 0) * Vector3(-angle.roll, -0.3, -1)
		
		self.effect = ClientEffect.Create(AssetLocation.Game, {
			effect_id = 11,
			position = LocalPlayer:GetPosition(),
			angle = Angle()
		})

		self.subs.grapple = Events:Subscribe("GameRender", function()
			
			local dt = self.timers.grapple:GetMilliseconds()			
			local bone_pos = LocalPlayer:GetBonePosition("ragdoll_LeftForeArm")
			
			local color = Color(100, 100, 100)
			local r = math.lerp(0.5 * color.r, color.r, self.dt)
			local g = math.lerp(0.5 * color.g, color.g, self.dt)
			local b = math.lerp(0.5 * color.b, color.b, self.dt)

			if not self.hit then
			
				local distance = self.tether_length * dt / 500
				local ray = Physics:Raycast(bone_pos, direction, 0, distance)
				
				Render:DrawLine(bone_pos, ray.position, Color(r, g, b, 192))

				if ray.distance < distance - 1 and ray.position.y > 200 then
					self.hit = ray.position
					self.vertical_speed = -self.vertical_speed
				end

				if dt > 500 then self:EndGrapple() end

			else

				Render:DrawLine(bone_pos, self.hit, Color(r, g, b, 192))
			 
				local yaw1 = math.atan2(bone_pos.x - self.hit.x, bone_pos.z - self.hit.z)
				local yaw2 = angle.yaw
				self.yaw = (yaw2 - yaw1 + math.pi) % (2 * math.pi) - math.pi

				if dt > 1500 or math.abs(self.yaw) > 0.2 * math.pi or Vector3.DistanceSqr(bone_pos, self.hit) > self.tether_length^2 then 
					self:EndGrapple() 
				end
	
			end
			
		end)
	
		return false
	
	end
		
	if self.blacklist.actions[args.input] then return false end

end

function Wingsuit:EndGrapple()

	self.timers.grapple:Restart()
	self.effect:Remove()
	LocalPlayer:SetLeftArmState(384)
	Events:Unsubscribe(self.subs.grapple)
	self.subs.grapple = nil
	self.hit = nil
	self.yaw = 0
	self.vertical_speed = self.default_vertical_speed

end

function Wingsuit:Abort()

	if self.subs.wings then Events:Unsubscribe(self.subs.wings) end
	if self.subs.velocity then Events:Unsubscribe(self.subs.velocity)end
	if self.subs.glide then Events:Unsubscribe(self.subs.glide) end
	if self.subs.input then Events:Unsubscribe(self.subs.input) end
	
	self.subs.wings = nil
	self.subs.velocity = nil
	self.subs.glide = nil
	self.subs.input = nil
	
	self.timers.camera_stop = Timer()

end

function Wingsuit:Camera()

	if self.timers.camera_start then
	
		local dt = self.timers.camera_start:GetMilliseconds()

		Camera:SetPosition(math.lerp(Camera:GetPosition(), LocalPlayer:GetPosition() + LocalPlayer:GetAngle() * Vector3(0, 2, 7), dt / 1000))
		Camera:SetAngle(Angle.Slerp(Camera:GetAngle(), LocalPlayer:GetAngle(), 0.9 * dt / 1000))

		if dt >= 1000 then 
			self.timers.camera_start = nil 
		end
		
	elseif self.timers.camera_stop then
	
		local dt = self.timers.camera_stop:GetMilliseconds()

		Camera:SetPosition(math.lerp(LocalPlayer:GetPosition() + LocalPlayer:GetAngle() * Vector3(0, 2, 7), Camera:GetPosition(), dt / 1000))
		Camera:SetAngle(Angle.Slerp(Camera:GetAngle(), LocalPlayer:GetAngle(), 0.9 - 0.9 * dt / 1000))

		if dt >= 1000 then 
			self.timers.camera_stop = nil
			Events:Unsubscribe(self.subs.camera)
			self.subs.camera = nil
		end	
		
	else
	
		Camera:SetPosition(LocalPlayer:GetPosition() + LocalPlayer:GetAngle() * Vector3(0, 2, 7))
		Camera:SetAngle(Angle.Slerp(Camera:GetAngle(), LocalPlayer:GetAngle(), 0.9))
		
	end

end

function Wingsuit:AddHelp()

	local text
	
	if self.superman then
		text = 
			"This wingsuit allows you to fly around Panau unencumbered." .. 
			"\n\nTo activate, double-tap Shift. To de-activate, double-tap Ctrl." ..
			"\nWhile flying, hold Shift to speed up or Ctrl to slow down."
	else
		if self.grapple then
			text = 
				"The wingsuit allows you to glide gently from the sky." .. 
				"\n\nTo activate, double-tap Shift while sky-diving or parachuting." ..
				"\nTo de-activate, double-tap Ctrl." ..
				"\nUse your grapple to propel yourself across land."	
		else
			text = 
				"The wingsuit allows you to fly around Panau unencumbered." .. 
				"\n\nTo activate, double-tap Shift while sky-diving or parachuting." ..
				"\nTo de-activate, double-tap Ctrl."
		end			
	end
	
	if self.rolls then
		text = text .. "\nDouble-tap left or right to roll."
	end

	Events:Fire("HelpAddItem", {
		name = "Wingsuit",
		text = text
	})

end

function Wingsuit:RemoveHelp()

	Events:Fire("HelpRemoveItem", {
		name = "Wingsuit"
	})

end

Wingsuit = Wingsuit()
