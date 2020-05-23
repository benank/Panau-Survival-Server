class 'cProxAlarm'

function cProxAlarm:__init(args)

    self.position = args.position
    self.angle = args.angle
    self.id = args.id

    self.localplayer_inside = false

    self:CreateAlarm()

    self.subs = 
    {
        Events:Subscribe(var("ShapeTriggerEnter"):get(), self, self.ShapeTriggerEnter),
        Events:Subscribe(var("ShapeTriggerExit"):get(), self, self.ShapeTriggerExit),
        --Events:Subscribe(var("GameRender"):get(), self, self.GameRender)
    }

    self.enabled = true

    Thread(function()
        while self.enabled do

            self.sound = ClientSound.Create(AssetLocation.Game, {
                bank_id = 8,
                sound_id = 0,
                position = self.position,
                angle = self.angle
            })
            
            self.sound:SetParameter(0,0)
            self.sound:SetParameter(1,0)
            self.sound:SetParameter(2,0.5)

            Timer.Sleep(1000)
            self.sound:Remove()
            Timer.Sleep(15000)

        end
    end)

end

function cProxAlarm:CanSeeLocalPlayer()

    if not self.localplayer_inside then return end

    local dir = (LocalPlayer:GetBonePosition("ragdoll_Spine") - self.position):Normalized()

    local angle = self.angle * Angle(0, math.pi / 2, 0)
    local start_ray_pos = self.position + angle * Vector3(0, 0, 0)

    local range = ItemsConfig.usables["Proximity Alarm"].range
    local ray = Physics:Raycast(start_ray_pos, dir, 0, range, false)

    local computed_angle = Angle.FromVectors(dir, Vector3.Down) * angle

    local dir_norm = computed_angle * Vector3.Forward

    if ray.entity and ray.entity.__type == "LocalPlayer" then
        if dir_norm.y < -0.3 then
            return true
        end
    end

end

function cProxAlarm:GameRender(args)
    --if self.owner_id ~= tostring(LocalPlayer:GetSteamId()) then return end
    --[[cProxAlarms:RenderRays(self.position, self.angle)
    
    local dir = (LocalPlayer:GetBonePosition("ragdoll_Spine") - self.position):Normalized()

    local angle = self.angle * Angle(0, math.pi / 2, 0)
    local start_ray_pos = self.position + angle * Vector3(0, 0, 0)

    local range = ItemsConfig.usables["Proximity Alarm"].range
    local ray = Physics:Raycast(start_ray_pos, dir, 0, range, false)

    local color = Color.Red

    if ray.entity then
        color = Color.Orange
    end

    Render:DrawLine(start_ray_pos, ray.position, color)]]

end

function cProxAlarm:ShapeTriggerEnter(args)
    if args.trigger ~= self.shapetrigger then return end
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if LocalPlayer:GetValue("Invincible") or LocalPlayer:GetValue("Invisible") then return end

    self.localplayer_inside = true
end

function cProxAlarm:ShapeTriggerExit(args)
    if args.trigger ~= self.shapetrigger then return end
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if LocalPlayer:GetValue("Invincible") or LocalPlayer:GetValue("Invisible") then return end

    self.localplayer_inside = false
end

function cProxAlarm:CreateAlarm()

    local radius = ItemsConfig.usables["Proximity Alarm"].range

    self.shapetrigger = ShapeTrigger.Create({
        position = self.position,
        angle = Angle(),
        components = {
            {
                type = TriggerType.Sphere,
                size = Vector3(radius,radius,radius),
                position = Vector3(0,0,0)
            }
        },
        trigger_player = true,
        trigger_player_in_vehicle = true,
        trigger_vehicle = true,
        trigger_npc = false,
        vehicle_type = VehicleTriggerType.All
    })

end

function cProxAlarm:Remove()
    if IsValid(self.shapetrigger) then self.shapetrigger:Remove() end
    if IsValid(self.sounds) then self.sound:Remove() end
    self.enabled = false
    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
        v = nil
    end
end