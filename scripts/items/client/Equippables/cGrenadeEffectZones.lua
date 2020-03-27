class 'GrenadeEffectZones'

function GrenadeEffectZones:__init()

    self.active_zones = {}

    Events:Subscribe(var("ShapeTriggerEnter"):get(), self, self.ShapeTriggerEnter)
    Events:Subscribe(var("ShapeTriggerExit"):get(), self, self.ShapeTriggerExit)
    Events:Subscribe(var("SecondTick"):get(), self, self.SecondTick)
    Events:Subscribe("Render", self, self.Render)
    
end

function GrenadeEffectZones:Render(args)
    for id, zone in pairs(self.active_zones) do
        if zone.timer:GetSeconds() >= zone.timeout then
            zone.trigger:Remove()
            self.active_zones[id] = nil
        end
    end 
end


function GrenadeEffectZones:SecondTick()
    for id, zone in pairs(self.active_zones) do

        if zone.inside_zone then
            -- Player is currently inside this zone

            -- apply damage, etc
            if zone.type == "Toxic" then
                Network:Send(var("items/PlayerInsideToxicGrenadeArea"):get())
            end
        end

    end
end

function GrenadeEffectZones:Add(position, grenade_type, type, timeout)

    print("add")
    local grenade_data = Grenade.Types[grenade_type]
    if not grenade_data then return end

    local zone = {
        trigger = ShapeTrigger.Create({
            position = position,
            angle = Angle(),
            components = {
                {
                    type = TriggerType.Sphere,
                    size = Vector3(grenade_data.radius, grenade_data.radius, grenade_data.radius),
                    position = Vector3(0,0,0)
                }
            },
            trigger_player = true,
            trigger_player_in_vehicle = false,
            trigger_vehicle = false,
            trigger_npc = false,
            vehicle_type = VehicleTriggerType.All
        }),
        type = type,
        inside_zone = false,
        timer = Timer(),
        timeout = timeout
    }

    self.active_zones[zone.trigger:GetId()] = zone

end

function GrenadeEffectZones:EnterZone(zone)
    zone.inside_zone = true

    if zone.type == "Fire" then
        Network:Send(var("items/PlayerInsideFireGrenadeArea"):get())
    end
end

function GrenadeEffectZones:ExitZone(zone)
    zone.inside_zone = false
end

function GrenadeEffectZones:ShapeTriggerEnter(args)
    if not self.active_zones[args.trigger:GetId()] then return end
    self:EnterZone(self.active_zones[args.trigger:GetId()])
end

function GrenadeEffectZones:ShapeTriggerExit(args)
    if not self.active_zones[args.trigger:GetId()] then return end
    self:ExitZone(self.active_zones[args.trigger:GetId()])
end

GrenadeEffectZones = GrenadeEffectZones()