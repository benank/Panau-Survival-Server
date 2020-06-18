class 'cTacticalNuke'

function cTacticalNuke:__init(args)

    self.position = args.position
    self.time_elapsed = args.timer
    self.attacker_id = args.attacker_id
    self.name = args.name
    self.seed = args.seed
    self.radius = args.radius
    self.timer = Timer()

    self.fx = {} -- Effects, sounds, and lights

    self:Initialize()

    self.events = 
    {
        Events:Subscribe("ModuleUnload", self, self.ModuleUnload),
        Events:Subscribe("Render", self, self.Render)
    }
end

-- Create initial flare and start countdown to bomb
function cTacticalNuke:Initialize()

    local time_before_strike = math.max(0, ItemsConfig.airstrikes[self.name].delay - self.time_elapsed)

    ClientEffect.Play(AssetLocation.Game, {
        position = self.position,
        angle = Angle(),
        effect_id = 130,
        timeout = time_before_strike
    })

    -- Flare light
    ClientLight.Play({
        position = self.position + Vector3.Up * 2,
        radius = self.radius,
        color = Color.Red,
        multiplier = 4,
        timeout = time_before_strike
    })

    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 23,
        sound_id = 0,
        position = self.position,
        angle = Angle()
    })
    
    sound:SetParameter(0,0)
    sound:SetParameter(1,1)
    sound:SetParameter(2,0)

    self.fx["alarm"] = sound

    Timer.SetTimeout(time_before_strike * 1000, function()
        self:Strike()
    end)

    Timer.SetTimeout((ItemsConfig.airstrikes[self.name].delay + time_before_strike) * 1000, function()
        self:ModuleUnload()
    end)

    Timer.SetTimeout(math.max(0, time_before_strike - 2) * 1000, function()
        
        self.missile_timer = Timer()
        self.fx.missile = ClientStaticObject.Create({
            position = self.position + Vector3.Up * 500,
            angle = Angle(0, math.pi, 0),
            model = "f3m04.rocket01.eez/key016_01-p1.lod"
        })

    end)

end

-- Create the actual airstrike
function cTacticalNuke:Strike()

    math.randomseed(self.seed)

    -- Remove alarm
    self.fx["alarm"]:Remove()
    self.fx["alarm"] = nil

    ClientEffect.Play(AssetLocation.Game, {
        position = self.position,
        angle = Angle(),
        effect_id = 132
    })

    Events:Fire(var("HitDetection/Explosion"):get(), {
        position = self.position,
        local_position = LocalPlayer:GetPosition(),
        type = DamageEntity.TacticalNuke,
        attacker_id = self.attacker_id
    })

end

function cTacticalNuke:Render(args)

    if IsValid(self.fx.missile) then
        local time_to_remove = 2.25
        self.fx.missile:SetPosition(math.lerp(self.position + Vector3.Up * 500, self.position, self.missile_timer:GetSeconds() / time_to_remove))
        
        if self.missile_timer:GetSeconds() > time_to_remove then
            self.fx.missile = self.fx.missile:Remove()
        end

    end

    -- Display time left if owner
    if self.attacker_id == tostring(LocalPlayer:GetSteamId()) then
        self:RenderCountdown()
    end

end

function cTacticalNuke:RenderCountdown()

    local time_left = math.max(0, ItemsConfig.airstrikes[self.name].delay - self.timer:GetSeconds())
    cAirstrikes:RenderCountdown(self.position, time_left)

end

function cTacticalNuke:ModuleUnload()
    for _, effect in pairs(self.fx) do
        if IsValid(effect) then effect:Remove() end
    end

    for _, event in pairs(self.events) do
        Events:Unsubscribe(event)
    end
end