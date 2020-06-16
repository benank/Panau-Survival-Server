class 'cProxAlarms'

function cProxAlarms:__init(args)

    self.alarms = {} -- [lootbox uid] = cProxAlarm() 

    self.placing_alarm = false

    self.ray_color = Color(0, 255, 0, 100)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    
    Network:Subscribe(var("items/StartProxPlacement"):get(), self, self.StartProxPlacement)
    Network:Subscribe(var("Items/ProximityPlayerDetected"):get(), self, self.ProximityPlayerDetected)
    Network:Subscribe("items/ProxExplode", self, self.ProxExplode)

    Events:Subscribe(var("Inventory/LootboxCreate"):get(), self, self.LootboxCreate)
    Events:Subscribe(var("Inventory/LootboxRemove"):get(), self, self.LootboxRemove)
    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)

end

function cProxAlarms:FireWeapon(args)
    local target = LocalPlayer:GetAimTarget()

    if not target.entity then return end
    if target.entity.__type ~= "ClientStaticObject" then return end

    local entity_pos = target.entity:GetPosition()
    local alarm_id
    for id, alarm in pairs(self.alarms) do
        if alarm.position:Distance(entity_pos) < 0.01 then
            alarm_id = id
            break
        end
    end

    if not alarm_id then return end

    Network:Send(var("items/DestroyProx"):get(), {id = alarm_id})

end

function cProxAlarms:ProxExplode(args)
    ClientEffect.Play(AssetLocation.Game, {
        effect_id = 92,
        position = args.position,
        angle = Angle()
    })
end

function cProxAlarms:ProximityPlayerDetected(args)
    cPingPlayerIndicators:AddPlayer(args)
end

function cProxAlarms:SecondTick()

    for id, alarm in pairs(self.alarms) do
        if alarm.localplayer_inside and alarm:CanSeeLocalPlayer() then
            -- Send to server, found player
            Network:Send("items/InsideProximityAlarm", {id = id})
        end
    end

end

function cProxAlarms:LootboxCreate(args)
    if args.tier ~= 14 then return end -- Not a proximity alarm

    if self.alarms[args.id] then
        self.alarms[args.id]:Remove()
    end

    self.alarms[args.id] = cProxAlarm(args)

end

function cProxAlarms:LootboxRemove(args)
    if args.tier ~= 14 then return end -- Not a proximity alarm

    local alarm = self.alarms[args.id]

    if not alarm then return end

    alarm:Remove()
    self.alarms[args.id] = nil

end

function cProxAlarms:StartProxPlacement()

    Events:Fire("build/StartObjectPlacement", {
        model = 'samsite.animated.eez/key036sam-d2.lod',
        offset = Vector3(0, 0, 0.125),
        angle = Angle(0, -math.pi / 2, 0)
    })

    self.place_subs = 
    {
        Events:Subscribe("ObjectPlacerGameRender", self, self.Render),
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_alarm = true
end

function cProxAlarms:RenderRays(pos, angle)

    local angle = angle * Angle(0, math.pi / 2, 0)
    local start_ray_pos = pos + angle * Vector3(0, 0, 0)

    angle = angle * Angle(0, math.pi / 2, 0)

    local range = ItemsConfig.usables["Proximity Alarm"].range

    local num_rays = 5
    for i = 1, num_rays do

        angle = angle * Angle(0, -math.pi / 6, 0)

        local ray = Physics:Raycast(start_ray_pos, angle * Vector3.Forward, 0, range, false)
        local end_ray_pos = ray.position

        Render:DrawLine(
            start_ray_pos,
            end_ray_pos,
            self.ray_color
        )

        local angle2 = angle * Angle(math.pi / 2, 0, 0)
        for i = 1, 5 do

            angle2 = angle2 * Angle(-math.pi / 6, 0, 0)

            local ray = Physics:Raycast(start_ray_pos, angle2 * Vector3.Forward, 0, range, false)
            local end_ray_pos = ray.position
    
            Render:DrawLine(
                start_ray_pos,
                end_ray_pos,
                self.ray_color
            )
        end

    end

end

function cProxAlarms:Render(args)

    if not self.placing_alarm then return end
    self:RenderRays(args.object:GetPosition(), args.object:GetAngle())

end

function cProxAlarms:PlaceObject(args)
    if not self.placing_alarm then return end

    if args.entity and args.entity.__type == "ClientStaticObject" then
        args.model = args.entity:GetModel()
    end

    Network:Send("items/PlaceProx", {
        position = args.position,
        angle = args.angle
    })

    self:StopPlacement()
end

function cProxAlarms:CancelObjectPlacement()
    Network:Send("items/CancelProxPlacement")
    self:StopPlacement()
end

function cProxAlarms:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_alarm = false
end

function cProxAlarms:ModuleUnload()

end

cProxAlarms = cProxAlarms()