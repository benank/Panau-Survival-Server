class 'cBeringBombsight'

function cBeringBombsight:__init(args)

    self.num_bombs = args.num_bombs

    self.missile_speed = 150 -- m/s
    self.distance = args.distance
    self.explosion_positions = {}
    self.vehicle = args.vehicle
    self.position = args.position
    self.time_elapsed = args.timer
    self.attacker_id = args.attacker_id
    self.name = args.name
    self.seed = args.seed
    self.radius = args.radius or ItemsConfig.airstrikes[self.name].radius
    self.timer = Timer()
    self.missile_launch_interval = 0.1

    self.fx = {} -- Effects, sounds, and lights

    self:Initialize()

    self.events = 
    {
        Events:Subscribe("ModuleUnload", self, self.ModuleUnload),
        Events:Subscribe("Render", self, self.Render)
    }
end

-- Start missiles immediately
function cBeringBombsight:Initialize()
    
    self:GenerateExplosionPositions()
    
    Thread(function()
        Timer.Sleep(1000 * 60)
        self:ModuleUnload()
    end)
    
end

function cBeringBombsight:GenerateExplosionPositions()
     
    math.randomseed(self.seed)

    for i = 1, self.num_bombs do
        local direction = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
        local pos = self.position + direction * self.radius * math.random()
        local ray = Physics:Raycast(pos + Vector3.Up * 500, Vector3.Down, 0, 1000)
        ray.position.y = math.max(200, ray.position.y)
        
        self.explosion_positions[i] = ray.position
    end
    
    math.randomseed(os.time())
    
end

function cBeringBombsight:Render(args)
    
    local seconds_elapsed = self.timer:GetSeconds()
    local origin_position = IsValid(self.vehicle) and self.vehicle:GetPosition() or self.position
    local num_active_missiles = math.min(self.num_bombs, math.ceil(seconds_elapsed / self.missile_launch_interval))
    local missile_strike_time = self.distance / self.missile_speed
    
    for i = 1, num_active_missiles do
        
        local missile_time = seconds_elapsed - (i - 1) * self.missile_launch_interval
        local missile_completion = missile_time / missile_strike_time
        
        if missile_completion >= 1 then
            if IsValid(self.fx[i]) then
                self.fx[i]:Remove()
                self.fx[i] = nil
                
                local position = self.explosion_positions[i]
                
                ClientEffect.Play(AssetLocation.Game, {
                    position = position,
                    angle = Angle(),
                    effect_id = 82
                })
                
                Events:Fire(var("HitDetection/Explosion"):get(), {
                    position = position,
                    local_position = LocalPlayer:GetPosition(),
                    type = DamageEntity.BeringBombsight,
                    attacker_id = self.attacker_id
                })
            
            end
        else
            if not IsValid(self.fx[i]) then
                self.fx[i] = ClientStaticObject.Create({
                    position = origin_position,
                    angle = Angle(0, -math.pi / 2, 0),
                    model = "general.blz/wea51-a.lod"
                })
            else
                self.fx[i]:SetPosition(math.lerp(origin_position, self.explosion_positions[i], missile_completion))
                self.fx[i]:SetAngle(Angle.FromVectors(Vector3.Forward, self.explosion_positions[i] - self.fx[i]:GetPosition()))
            end
        end
    end

end

function cBeringBombsight:ModuleUnload()
    for _, effect in pairs(self.fx) do
        if IsValid(effect) then effect:Remove() end
    end

    for _, event in pairs(self.events) do
        Events:Unsubscribe(event)
    end
end