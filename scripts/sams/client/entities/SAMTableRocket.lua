class 'SAMTableRocket' (Entity)

function SAMTableRocket:__init(args)
	self.expired = false
	--	Missile Config	--
	self.name					=	args.name
	self.Stats					=	args.statsTable
	self.Type					=	args.statsTable.Class
	self.vehicleName			=	args.statsTable.Name
	self.DisplayTitle			=	"[" .. self.vehicleName .. " " .. self.Type .. "]"
	self.MissileDamage			=	args.statsTable.Damage
	self.MissileRadius			=	args.statsTable.Radius
	self.max_speed				=	args.statsTable.MaxSpeed
	self.booster_acceleration	=	self.max_speed / args.statsTable.Booster
	self.max_turn_angle			=	args.statsTable.TurnRate
	self.fuel					=	args.statsTable.Range
	--	Visual and Physical Stats	--
	self.FireEffectID			=	args.statsTable.FireEffect
	self.MissileEffectID		=	args.statsTable.ProjectileEffect
	self.ImpactEffectID			=	table.randomvalue(EffectTableExplosionMedium)
	self.MissileObjectID		=	args.statsTable.ObjectModel
	self.MissileObjectCollision	=	args.statsTable.ObjectCollision
	self.TrackingBeep			=	args.statsTable.Beep
	--	Debug and Note Info	--
	self.note					=	args.statsTable.Note
	self.string					=	args.string
	self.print					=	args.print
	self.color					=	SAMMissileMiniMapColor
	
	self.co = coroutine.create(self.YieldableStep)
	self.timer = Timer()

	self.position = args.originPosition
	self.angle = args.originAngle


	self.projectile = nil
	self.booster_stage = true
	self.speed = 0	--args.senderObject:GetLinearVelocity():Length()

	self.detonate = false
	self.detonation_point = nil

	self.target = nil
	self.target_position = nil
	self.target_entity = args.targetObject
	
	self.sender_entity = args.senderObject
	self.sender_position = args.senderObject:GetPosition()
	self.sender_color = args.senderObject:GetColor()
		
	self.SafetyTimer	=	Timer()
		
	MaxFuel						=	self.fuel	--	Sets the MaxFuel variable, do not change.
end

function SAMTableRocket:IsExpired()
	return self.expired
end

function SAMTableRocket:Expire()
	self.expired = true
end

function SAMTableRocket:Tick(dt)
end

function SAMTableRocket:Draw()
end

function SAMTableRocket:Remove()
end

function SAMTableRocket:GetPosition()
	return self.position
end

function SAMTableRocket:__tostring()
--	self.DisplayDamage	=	"Damage: " .. Round(self.MissileDamage * 100, 1)
	self.DisplayRange	=	"Range: " .. Commas(Round(self.fuel, 0)) .. "m"
	self.DisplayCurrentSpeed	=	Commas(Round(self.speed, 0))
	self.DisplayMaxSpeed	=	Commas(Round(self.max_speed, 0))
	if LocalPlayer:GetValue("Speedometer") then
		self.DisplayCurrentSpeed	=	Commas(Round(self.speed * tonumber(LocalPlayer:GetValue("Speedometer")), 0))
		self.DisplayMaxSpeed	=	Commas(Round(self.max_speed * tonumber(LocalPlayer:GetValue("Speedometer")), 0))
	end
	self.DisplaySpeed	=	"Speed: " .. self.DisplayCurrentSpeed .. "/" .. self.DisplayMaxSpeed
	self.DisplayTargetName	=	"Target: None"
	if IsValid(self.target_entity) then
		self.DisplayTargetName	=	"Target: " .. self.target_entity:GetName()
	end
	self.Proximity			=	Commas(Round(Vector3.Distance(LocalPlayer:GetPosition(), self.position), 0))
	self.DisplayProximity	=	"Proximity: " .. self.Proximity .. "m"
	
	self.ReturnString	=	string.format(
								self.DisplayTitle .. " " ..
								self.DisplayTargetName .. ", " ..
--								self.DisplayDamage .. ", " ..
								self.DisplaySpeed .. ", " ..
								self.DisplayRange .. ", " ..
								self.DisplayProximity
										)
	return self.ReturnString
end

function SAMTableRocket:Draw()
	if Game:GetState() ~= GUIState.Game then return end
	Render:FillCircle(Render:WorldToMinimap(self.projectile:GetPosition()), SAMMissileMiniMapRadius, self.color)
end

function SAMTableRocket:Tick(dt)
	self.dt = dt

	-- Above all else, we need to check for detonations
	self:DetonationCheck()

	-- Run the coroutine and print out any errors it might encounter
	local success, error_message = coroutine.resume(self.co, self)
	if not success then
		error(error_message)
	end
end

function SAMTableRocket:Remove()
	if self.projectile then
		self.projectile:Remove()
		self.projectile = nil
		self.projectileObject:Remove()
		self.projectileObject = nil
	end
end

function SAMTableRocket:DetonationCheck()
	--	Wait a moment to check Detonation to make sure it doesn't explode on firing.
	if self.SafetyTimer:GetMilliseconds() < MissileSafetyCheckInteger then return end
	-- No point doing checks if we don't have a projectile
	if not self.projectile then
		return
	end

	if self.fuel <= 0 then
		self.detonate = true
		self.detonation_point = self.position
	end
	
	-- Maximum distance we can travel in one frame. This varies
	-- drastically according to FPS. If we search a set distance, its
	-- quite possible that the collision check will fail in cases
	-- where framerates tank. In these situations, the missile would otherwise
	-- skip right through the target.
	local max_travel = self.dt * self.speed
	local ray = Physics:Raycast(self.position, (self.angle * Vector3(0, 0, 1)), 0, max_travel)

	-- Did our ray collide with something?
	if (max_travel - ray.distance) > 0.001 then
		self.detonate = true
		self.detonation_point = ray.position
	end

	-- So our ray didn't hit the target. What if the target is in open 
	-- space, without a collision?
	if Vector3.Distance(self.position, self:GetTargetPosition()) < 5 then
		self.detonate = true
		self.detonation_point = self:GetTargetPosition()	--self.position
	end
end

function SAMTableRocket:YieldableStep()
	-- Calculate a point in front of the provided origin
	local direction = self.angle
	local start_pos = self.position + ((direction * Vector3.Forward) * 2.5)

	-- First thing that occurs when you fire a missile?
	-- Flames, of course!
	self:PlayFireEffect(start_pos)

	-- We also need a projectile!
	self:CreateProjectile(start_pos)

	-- We have a ploom and a projectile. Time to simulate it.
	while not self:IsExpired() do
		self:Step()
		coroutine.yield()
	end
end

function SAMTableRocket:Step()
	if self.detonate then
		self:Detonate()

		return
	end

	-- If we ran out of fuel, its game over. Thanks for playing!
	if self.fuel <= 0 then
		self:Expire()
	end

	-- If we were just fired, we need to gradually speed up
	-- to an acceptable speed. We obey the laws of physics (sometimes)!
	if self.booster_stage then
		self:BoosterStage()
	end

	local dir_to_target = self.angle
	-- If we're aiming for a target, calculate the angle to it.
	-- Otherwise, Forward is fine.
	if self:HasTarget() then
		dir_to_target = Angle.NormalisedDir(self:GetTargetPosition(), self.position)
		dir_to_target = Angle.FromVectors(Vector3.Forward, dir_to_target)
	end

	-- Calculate the new angle to the target, taking into account the maximum 
	-- turning angle.
	local new_angle	= Angle.RotateToward(self.angle, dir_to_target, math.rad(self.max_turn_angle * self.dt))

	self:SimulateMovement(new_angle)
end

function SAMTableRocket:BoosterStage()
	local start_time = Timer()
	local direction = self.angle * Vector3.Forward

	while not self.detonate and self.speed < self.max_speed do
		self.speed = self.speed + (self.booster_acceleration * self.dt)
		self:SimulateMovement(self.angle)

		coroutine.yield()
	end

	self.booster_stage = false
end

function SAMTableRocket:SimulateMovement(angle)
	local direction = angle * Vector3.Forward

	-- Simulate velocity
	self.position = self.projectile:GetPosition() + (direction * (self.speed * self.dt))
	self.angle = angle

	self.projectile:SetPosition(self.position)
	self.projectile:SetAngle(self.angle)
	self.projectileObject:SetPosition(self.position)
	self.projectileObject:SetAngle(self.angle * Angle(0, math.pi * 1.5, 0))

	if IsValid(self.TrackingBeep) then
		self.TrackingBeep:SetPosition(self.position)
		self.TrackingBeep:SetAngle(self.angle)
	end
	
	self.fuel = self.fuel - (self.speed * self.dt)
end

function SAMTableRocket:Detonate()
	-- Remove our projectile
	self.projectile:Remove()
	self.projectile = nil
	self.projectileObject:Remove()
	self.projectileObject = nil
	
	if IsValid(self.TrackingBeep) then
		self.TrackingBeep:Remove()
		self.TrackingBeep	=	nil
	end
	
	-- Play the detonation effect
	ClientEffect.Play(AssetLocation.Game, {
		effect_id = self.ImpactEffectID,
		position = self.detonation_point,
		angle = Angle()
	})
		self:MissileStrike()
	-- We've completed our task. Goodbye
	self:Expire()
end

function SAMTableRocket:MissileStrike()
	local PlayerPosition	=	LocalPlayer:GetPosition()
	local BlastEpicenter	=	self.detonation_point
	local BlastRadius		=	self.MissileRadius
	if Immune(LocalPlayer) then
		return
	end
	
	if Vector3.Distance(BlastEpicenter, PlayerPosition) <= BlastRadius then
		DamageInformationTable				=	{}
		DamageInformationTable.player		=	LocalPlayer
		DamageInformationTable.epicenter	=	BlastEpicenter
		DamageInformationTable.sam_id 		=	self.Stats.sam_id 
		DamageInformationTable.Stats		=	self.Stats
		Network:Send("sams/MissileStrikeDamagePlayer", DamageInformationTable)
	end
end

function SAMTableRocket:PlayFireEffect(start_pos)
	-- We rotate the angle by 90 degrees to match the offset
	-- rotation of the effect emitter.
	ClientEffect.Play(AssetLocation.Game, {
		effect_id = self.FireEffectID,
		position = start_pos,
		angle = self.angle * Angle(math.pi/2, 0, 0)
	})
end

function SAMTableRocket:CreateProjectile(start_pos)
	self.projectile = ClientEffect.Create(AssetLocation.Game, {
		effect_id = self.MissileEffectID,
		position = start_pos,
		angle = self.angle
	})
	if self.TrackingBeep then
		self.TrackingBeep = ClientEffect.Create(AssetLocation.Game, {
			effect_id = 66,
			position = start_pos,
			angle = self.angle
		})
	end
	if IsValid(self.target_entity) then
		if not IsValidVehicle(self.target_entity:GetModelId(), VehicleTablePlanes) then
			self.projectileObject = ClientStaticObject.Create({
				position = start_pos,
				angle = self.angle,
				model = self.MissileObjectID,
				collision = self.MissileObjectCollision
			})
		else
			self.projectileObject = ClientStaticObject.Create({
				position = start_pos,
				angle = self.angle,
				model = self.MissileObjectID,
				collision = ""
			})
		end
	else
		self.projectileObject = ClientStaticObject.Create({
			position = start_pos,
			angle = self.angle,
			model = self.MissileObjectID,
			collision = ""
		})
	end
end

function SAMTableRocket:HasTarget()
	return self.target_entity or self.target_position
end

function SAMTableRocket:GetTargetPosition()
	-- Are we chasing some vehicle/player?
	if self.target_entity then
		if IsValid(self.target_entity) then
			return self.target_entity:GetPosition()
		end
	elseif self.target_position then
		return self.target_position
	end

	--	Return Randomness
	return Vector3(math.random(-16000, 16000), math.random(200, 6000), math.random(-16000, 16000)) * 10

	-- Well, we have no special target.. this shouldn't be 
	-- operated on, so return zero.
--	return Vector3.Zero
end