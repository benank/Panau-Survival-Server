class "Grenade"

Grenade.FlashTime = 7 -- Max flashbang white screen time

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

	["HE Grenade"] = {
		["effect_id"] = 411,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
        ["trigger_explosives"] = true,
		["restitution"] = 0.3,
		["radius"] = 8,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 5
	},
	["Laser Grenade"] = {
		["effect_id"] = 344,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
        ["trigger_explosives"] = true,
		["restitution"] = 0.3,
		["radius"] = 8,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 5
	},
	["Warp Grenade"] = {
		["effect_id"] = 251,
        ["trail_effect_id"] = 61,
		["weight"] = 0.5,
        ["drag"] = 0.11,
        ["trigger_explosives"] = true,
		["restitution"] = 0.3,
		["radius"] = 8,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 5
	},
	["Flashbang"] = {
		["effect_id"] = 19,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
		["restitution"] = 0.3,
		["radius"] = 50,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 5
	},
	["Toxic Grenade"] = {
		["effect_id"] = 184,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
		["restitution"] = 0.3,
        ["radius"] = 12,
        ["custom_func"] = function(grenade)

            GrenadeEffectZones:Add({
                position = grenade.position, 
                grenade_type = grenade.grenade_type, 
                type = "Toxic",
                timeout = grenade.type.effect_time,
                owner_id = grenade.owner_id
            })
            
            local function createfx()
                for i = 1, 6 do
                    ClientEffect.Play(AssetLocation.Game, {
                        ["position"] = grenade.position,
                        ["angle"] = Angle(),
                        ["effect_id"] = grenade.effect_id
                    })
                end
            end

            createfx()

            Timer.SetTimeout(15 * 1000, function()
                createfx()
            end)

            ClientLight.Play({
                position = grenade.position + Vector3(0, 10, 0),
                angle = Angle(),
                color = Color(64, 200, 28),
                multiplier = 1,
                radius = 22,
                timeout = grenade.type.effect_time
            })
        end,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 30 -- default effect time for this effect is 15
	},
	["AntiGrav Grenade"] = {
		["effect_id"] = 135,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
		["restitution"] = 0.3,
        ["radius"] = 12,
        ["custom_func"] = function(grenade)

            GrenadeEffectZones:Add({
                position = grenade.position, 
                grenade_type = grenade.grenade_type, 
                type = "Slow",
                timeout = grenade.type.effect_time,
                owner_id = grenade.owner_id
            })

            local timer = Timer()
            
            local function createfx()
                ClientParticleSystem.Play(AssetLocation.Game, {
                    position = grenade.position,
                    timeout = 3,
                    angle = Angle(),
                    path = "fx_f2m06_emptoweractive_05.psmb"
                })

                if timer:GetSeconds() < grenade.type.effect_time then
                    Timer.SetTimeout(2 * 1000, function()
                        createfx()
                    end)
                end

            end

            createfx()

            ClientLight.Play({
                position = grenade.position + Vector3(0, 10, 0),
                angle = Angle(),
                color = Color(255, 255, 255),
                multiplier = 3,
                radius = 15,
                timeout = grenade.type.effect_time
            })
        end,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 30 -- default effect time for this effect is 15
	},
	["Flares"] = {
        ["effect_id"] = 266,
        ["effect_angle"] = Angle(0, -math.pi / 12, 0),
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
        --["repeat_interval"] = 2000, -- effect repeats
        --["repeat_effect_id"] = 236,
		["restitution"] = 0.3,
		["radius"] = 0,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 30,
        ["custom_func"] = function(grenade)
            Timer.SetTimeout(7000, function()
                ClientParticleSystem.Play(AssetLocation.Game, {
                    position = grenade.position + Vector3(0, 81, 5),
                    timeout = 8,
                    angle = Angle(),
                    path = "fx_flare_02.psmb"
                })
            end)
            
            Timer.SetTimeout(14000, function()
                ClientParticleSystem.Play(AssetLocation.Game, {
                    position = grenade.position + Vector3(0, 81, 5),
                    timeout = 8,
                    angle = Angle(),
                    path = "fx_flare_02.psmb"
                })
            end)

            Timer.SetTimeout(21000, function()
                ClientParticleSystem.Play(AssetLocation.Game, {
                    position = grenade.position + Vector3(0, 81, 5),
                    timeout = 8,
                    angle = Angle(),
                    path = "fx_flare_02.psmb"
                })
            end)

            Timer.SetTimeout(1000, function()
                ClientLight.Play({
                    position = grenade.position + Vector3(0, 110, 0),
                    angle = Angle(),
                    color = Color(252, 73, 60),
                    multiplier = 10,
                    radius = 500,
                    timeout = 30
                })
            end)
        end
	},
	["Smoke Grenade"] = {
		["effect_id"] = 71,
        ["trail_effect_id"] = 61,
		["weight"] = 0.7,
        ["drag"] = 0.12,
        ["repeat_interval"] = 250, -- effect repeats
        ["custom_func"] = function(grenade)
            if grenade.type.repeat_interval then
                ClientParticleSystem.Play(AssetLocation.Game, {
                    ["position"] = grenade.position,
                    ["angle"] = Angle(),
                    ["path"] = "fx_env_oilrig_tophouse_02.psmb"
                })

                Timer.SetTimeout(grenade.type.repeat_interval, function()
                    if grenade.detonation_timer:GetSeconds() < grenade.type.effect_time - grenade.type.repeat_interval / 1000 then
                        grenade.type.custom_func(grenade)
                    end
                end)
            end
        end,
		["restitution"] = 0.3,
		["radius"] = 0,
        ["model"] = "general.blz/wea33-wea33.lod",
        ["offset"] = Vector3(-0.32, 0, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["effect_time"] = 30
	},
	["Molotov"] = {
        ["effect_id"] = 452,
        ["trail_effect_id"] = 326,
		["weight"] = 0.7,
        ["drag"] = 0.12,
        ["trigger_explosives"] = true,
		["restitution"] = 0,
        ["radius"] = 3,
        ["repeat_interval"] = 5000,
        ["repeat_effect_id"] = 30,
        ["custom_func"] = function(grenade)

            if grenade.position.y < 200 then return end

            GrenadeEffectZones:Add({
                position = grenade.position,
                grenade_type = grenade.grenade_type, 
                type = "Fire", 
                timeout = grenade.type.effect_time,
                owner_id = grenade.owner_id
            })

            local function func(grenade)
                if grenade.type.repeat_interval then
                    ClientEffect.Play(AssetLocation.Game, {
                        ["position"] = grenade.position,
                        ["angle"] = Angle(),
                        ["effect_id"] = grenade.type.repeat_effect_id or grenade.type.effect_id
                    })

                    Timer.SetTimeout(grenade.type.repeat_interval, function()
                        if grenade.detonation_timer:GetSeconds() < grenade.type.effect_time - grenade.type.repeat_interval / 1000 * 0.9 then
                            func(grenade)
                        end
                    end)
                end
            end

            func(grenade)

        end,
		["explode_on_contact"] = true,
        ["model"] = "km05.market.nl/go168-d.lod",
        ["offset"] = Vector3(-0.32, -0.08, 0.03),
        ["angle"] = Angle(0, math.pi / 2, 0),
        ["extra_effect_id"] = 326, -- Effect that is attached to bottle as it is thrown
        ["effect_time"] = 30
	}
}

local GRENADE_ID = 0
local function GET_GRENADE_ID()
    GRENADE_ID = GRENADE_ID + 1
    return GRENADE_ID
end

function Grenade:__init(args)
    self.id = GET_GRENADE_ID()
	self.object = ClientStaticObject.Create({
		["position"] = args.position,
		["angle"] = Angle.FromVectors(args.velocity, Vector3.Forward),
		["model"] = Grenade.Types[args.type].model
	})
	self.effect = ClientEffect.Create(AssetLocation.Game, {
		["position"] = self.object:GetPosition(),
		["angle"] = self.object:GetAngle(),
		["effect_id"] = Grenade.Types[args.type].trail_effect_id
    })
    
    if args.type ~= "Molotov" and args.fusetime > 0 then

        Timer.SetTimeout(math.max(0, (args.fusetime - 3.5)) * 1000, function()
            
            self.sound = ClientSound.Create(AssetLocation.Game, {
                bank_id = 11,
                sound_id = 6,
                position = self.object:GetPosition(),
                angle = Angle()
            })

            self.sound:SetParameter(0,1 - math.min(1, args.fusetime / 3.5)) -- 3.5 total, 
            self.sound:SetParameter(1,0.75)
            self.sound:SetParameter(2,0)

            Timer.SetTimeout(args.fusetime * 1000, function()
                self.sound:Remove()
            end)
        
        end)

    end


    self.repeating_fx = {}
    
    self.velocity = args.velocity
    self.grenade_type = args.type
	self.type = Grenade.Types[args.type]
	self.weight = self.type.weight
	self.drag = self.type.drag
	self.restitution = self.type.restitution
	self.radius = self.type.radius
	self.fusetime = args.fusetime
	self.effect_id = self.type.effect_id
	self.timer = Timer()
    self.lastTime = 0
    self.detonated = false
    self.is_mine = args.is_mine == true
    self.owner_id = self.is_mine and tostring(LocalPlayer:GetSteamId()) or args.owner_id
end

function Grenade:Update()
    local delta = (self.timer:GetSeconds() - self.lastTime) / 1
    if self.detonated then return end

    if self.timer:GetSeconds() < self.fusetime or self.type.explode_on_contact then
        if not self.stopped then
            local old_velocity = self.velocity
			self.velocity = (self.velocity - (self.velocity * self.drag * delta)) + (Vector3.Down * self.weight * 9.81 * delta)

			local ray = Physics:Raycast(self.object:GetPosition(), self.velocity * delta, 0, 1, true)

			if ray.distance <= math.min(self.velocity:Length() * delta, 1) then
				if self.type.explode_on_contact then
					self:Detonate()
				else
					local dotTimesTwo = 2 * self.velocity:Dot(ray.normal)

					self.velocity.x = self.velocity.x - dotTimesTwo * ray.normal.x
					self.velocity.y = self.velocity.y - dotTimesTwo * ray.normal.y
					self.velocity.z = self.velocity.z - dotTimesTwo * ray.normal.z
					self.velocity = self.velocity * self.restitution

					if (self.velocity * delta):Length() <= 0.005 then
                        self.stopped = true
                    end
                    
                    -- Play sound of grenade bouncing
                    local sound = ClientSound.Create(AssetLocation.Game, {
                        bank_id = 17,
                        sound_id = 37,
                        position = self.object:GetPosition(),
                        angle = Angle()
                    })
                    
                    sound:SetParameter(0,0.5)
                    sound:SetParameter(1,0)
                    sound:SetParameter(2,0)

                end
                

            end
            
            if IsValid(self.object) and IsValid(self.effect) then
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
            
            if IsValid(self.sound) and IsValid(self.object) then self.sound:SetPosition(self.object:GetPosition()) end
		end
	elseif not self.type.explode_on_contact then
		self:Detonate()
	end

	self.lastTime = self.timer:GetSeconds()
end

function Grenade:GetDamageEntity()
    return ItemsConfig.equippables.grenades[self.grenade_type]
end

function Grenade:Detonate()
    if self.detonated then return end

    self.detonated = true

	if not table.compare(self.type, Grenade.Types.Flashbang) then
        Events:Fire(var("HitDetection/Explosion"):get(), {
			position = self.object:GetPosition(),
            type = self:GetDamageEntity(),
            local_position = LocalPlayer:GetPosition(),
            attacker_id = self.owner_id
        })
        
        if self.is_mine and Grenade.Types[self.grenade_type].trigger_explosives then
            Network:Send(var("items/GrenadeExploded"):get(), {
                position = self.object:GetPosition(),
                radius = self.type.radius,
                type = self.grenade_type
            })
        end

	elseif table.compare(self.type, Grenade.Types.Flashbang) then
		local position, onscreen = Render:WorldToScreen(self.object:GetPosition())
		local distance = self.object:GetPosition():Distance(Camera:GetPosition())
		local direction = (self.object:GetPosition() - Camera:GetPosition()):Normalized()
		local ray = Physics:Raycast(Camera:GetPosition(), direction, 0, distance)

		if onscreen and ray.distance == distance and ray.distance < self.radius then
            Grenades.flashed_time = (1 - ray.distance / self.radius) * Grenade.FlashTime
			Grenades.flashed = true
            Grenades.flashedOpacity = 255
			Grenades.flashedTimer:Restart()
		elseif not onscreen and ray.distance == distance and ray.distance < self.radius and Camera:GetAngle():Dot(Angle.FromVectors(Vector3.Forward, direction)) > 0.65 then
            Grenades.flashed_time = (1 - ray.distance / self.radius) * Grenade.FlashTime
			Grenades.flashed = true
			Grenades.flashedOpacity = 150
			Grenades.flashedTimer:Restart()
		end
    end
    
	ClientEffect.Play(AssetLocation.Game, {
		["position"] = self.object:GetPosition(),
		["angle"] = self.type.effect_angle or Angle(),
		["effect_id"] = self.effect_id
    })

    self.detonation_timer = Timer()
    self.position = self.object:GetPosition()

    if self.type.custom_func then
        self.type.custom_func(self)
    end

    Timer.SetTimeout(1000 * self.type.effect_time, function()
        Grenades.grenades[self.id] = nil
    end)

    self:Remove()
    
end

function Grenade:Remove()
    if IsValid(self.object) then self.object:Remove() end
	if IsValid(self.effect) then self.effect:Remove() end
end
