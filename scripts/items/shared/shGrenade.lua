class "Grenade"

Grenade.FlashTime = 3

Grenade.Types = {
	-- Type Explanation (For Jman):
	--    Effect ID: The effect you'd like to play
	--    Weight: This determines how far you can throw a grenade
	--    Drag: This determines how much energy is lost as a grenade travels through the air
	--    Restitution: This determines how much energy is left after each bounce (0 would be a sticky grenade, 1 would be a rubber ball that defys physics)
	--    Radius: This determines the area of effect for a given grenade (For the flashbang this determines the max distance at which you will be blinded)
	--    Fusetime: This determines how much time should pass before a grenade explodes (For the flashbang this is ignored if it hits a surface)
	--
	--    If you want to add an specific behaviours then please do so in the code below and in client/grenades.lua & server/grenades.lua
	--    In the future I might add callbacks to the following "Types" so that you can define what should occur for certain events.

    -- 266 flare

    -- flare smoke: 118/km07_cylinder_e.bin (get ClientParticleEffect for smoke)

	["Grenade"] = {
		["effect_id"] = 35,
		["weight"] = 1,
		["drag"] = 0.15,
		["restitution"] = 0.2,
		["radius"] = 6,
		["fusetime"] = 3
	},
	["HE Grenade"] = {
		["effect_id"] = 411,
		["weight"] = 1,
		["drag"] = 0.15,
		["restitution"] = 0.2,
		["radius"] = 12,
		["fusetime"] = 3
	},
	["Flashbang"] = {
		["effect_id"] = 19,
		["weight"] = 1,
		["drag"] = 0.15,
		["restitution"] = 0,
		["radius"] = 150,
		["fusetime"] = 3
	},
	["Toxic"] = {
		["effect_id"] = 184,
		["weight"] = 1,
		["drag"] = 0.15, -- 70, 
		["restitution"] = 0.2,
		["radius"] = 0,
		["fusetime"] = 4
	},
	["Smoke"] = {
		["effect_id"] = 184,
		["weight"] = 1,
		["drag"] = 0.15, -- 70, 236
		["restitution"] = 0.2,
		["radius"] = 0,
		["fusetime"] = 4
	},
	["Molotov"] = {
		["effect_id"] = 129, -- 326 for molotov trail, 30 for effect on ground
		["weight"] = 2,
		["drag"] = 0.15,
		["restitution"] = 0,
		["radius"] = 20,
		["fusetime"] = 4
	}
}

function Grenade:__init(position, velocity, type)
	self.object = ClientStaticObject.Create({
		["position"] = position,
		["angle"] = Angle.FromVectors(velocity, Vector3.Forward),
		["model"] = "wea33-wea33.lod"
	})
	self.effect = ClientEffect.Create(AssetLocation.Game, {
		["position"] = self.object:GetPosition(),
		["angle"] = self.object:GetAngle(),
		["effect_id"] = 61
	})
	self.velocity = velocity
	self.type = type or Grenade.Types.Frag
	self.weight = self.type.weight
	self.drag = self.type.drag
	self.restitution = self.type.restitution
	self.radius = self.type.radius
	self.fusetime = self.type.fusetime
	self.effect_id = self.type.effect_id
	self.timer = Timer()
	self.lastTime = 0
end

function Grenade:Update()
	local delta = (self.timer:GetSeconds() - self.lastTime) / 1

	if self.timer:GetSeconds() < self.fusetime then
		if not self.stopped then
			self.velocity = (self.velocity - (self.velocity * self.drag * delta)) + (Vector3.Down * self.weight * 9.81 * delta)

			local ray = Physics:Raycast(self.object:GetPosition(), self.velocity * delta, 0, 1, true)

			if ray.distance <= math.min(self.velocity:Length() * delta, 1) then
				if table.compare(self.type, Grenade.Types.Flashbang) then
					self:Detonate()
				else
					local dotTimesTwo = 2 * self.velocity:Dot(ray.normal)

					self.velocity.x = self.velocity.x - dotTimesTwo * ray.normal.x
					self.velocity.y = self.velocity.y - dotTimesTwo * ray.normal.y
					self.velocity.z = self.velocity.z - dotTimesTwo * ray.normal.z
					self.velocity = self.velocity * self.restitution

					if (self.velocity * delta):Length() <= 0.01 then
						self.stopped = true
					end
				end
			end

			if not self.stopped then
				self.object:SetPosition(self.object:GetPosition() + (self.velocity * delta))
				self.effect:SetPosition(self.object:GetPosition())
				self.object:SetAngle(Angle.FromVectors(self.velocity, Vector3.Right))
				self.effect:SetAngle(self.object:GetAngle())
			else
				self.object:SetPosition(self.object:GetPosition() + (Vector3.Up * 0.05))
				self.effect:SetPosition(self.object:GetPosition())
			end
		end
	else
		self:Detonate()
	end

	self.lastTime = self.timer:GetSeconds()
end

function Grenade:Detonate()
	if not table.compare(self.type, Grenade.Types.Flashbang) then
		Network:Send("GrenadeExplode", {
			["position"] = self.object:GetPosition(),
			["angle"] = self.object:GetAngle(),
			["type"] = self.type
		})
	elseif table.compare(self.type, Grenade.Types.Flashbang) then
		local position, onscreen = Render:WorldToScreen(self.object:GetPosition())
		local distance = self.object:GetPosition():Distance(Camera:GetPosition())
		local direction = (self.object:GetPosition() - Camera:GetPosition()):Normalized()
		local ray = Physics:Raycast(Camera:GetPosition(), direction, 0, distance)

		if onscreen and ray.distance == distance and ray.distance < self.radius then
			Grenades.flashed = true
			Grenades.flashedOpacity = 255
			Grenades.flashedTimer:Restart()
		elseif not onscreen and ray.distance == distance and ray.distance < self.radius and Camera:GetAngle():Dot(Angle.FromVectors(Vector3.Forward, direction)) > 0.65 then
			Grenades.flashed = true
			Grenades.flashedOpacity = 100
			Grenades.flashedTimer:Restart()
		end
	end

	ClientEffect.Play(AssetLocation.Game, {
		["position"] = self.object:GetPosition(),
		["angle"] = Angle(),
		["effect_id"] = self.effect_id
	})
	self:Remove()
end

function Grenade:Remove()
	self.object:Remove()
	self.effect:Remove()
end
