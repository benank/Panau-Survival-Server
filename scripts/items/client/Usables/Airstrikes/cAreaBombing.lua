class 'cAreaBombing'

function cAreaBombing:__init(args)

    self.num_bombs = args.num_bombs

    self.position = args.position
    self.time_elapsed = args.timer
    self.attacker_id = args.attacker_id
    self.name = args.name
    self.seed = args.seed
    self.radius = ItemsConfig.airstrikes[self.name].radius
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
function cAreaBombing:Initialize()

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

end

-- Create the actual airstrike
function cAreaBombing:Strike()

    math.randomseed(self.seed)

    -- Remove alarm
    self.fx["alarm"]:Remove()
    self.fx["alarm"] = nil

    Thread(function()

        math.randomseed(self.seed)

        for i = 1, self.num_bombs do
            local direction = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
            local pos = self.position + direction * self.radius * math.random()
            local ray = Physics:Raycast(pos + Vector3.Up * 500, Vector3.Down, 0, 1000)
            ray.position.y = math.max(200, ray.position.y)
                
            ClientEffect.Play(AssetLocation.Game, {
                position = ray.position,
                angle = Angle(),
                effect_id = 82
            })

            Events:Fire(var("HitDetection/Explosion"):get(), {
                position = ray.position,
                local_position = LocalPlayer:GetPosition(),
                type = DamageEntity.AreaBombing,
                attacker_id = self.attacker_id
            })
            Timer.Sleep(300 + math.random() * 500)
        end

    end)

end

function cAreaBombing:Render(args)

    -- Display time left if owner
    if self.attacker_id == tostring(LocalPlayer:GetSteamId()) then
        self:RenderCountdown()
    end

end

function cAreaBombing:RenderCountdown()

    local time_left = math.max(0, ItemsConfig.airstrikes[self.name].delay - self.timer:GetSeconds())
    cAirstrikes:RenderCountdown(self.position, time_left)

end

function cAreaBombing:ModuleUnload()
    for _, effect in pairs(self.fx) do
        if IsValid(effect) then effect:Remove() end
    end

    for _, event in pairs(self.events) do
        Events:Unsubscribe(event)
    end
end