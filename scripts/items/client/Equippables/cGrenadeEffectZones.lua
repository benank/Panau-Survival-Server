class 'GrenadeEffectZones'

function GrenadeEffectZones:__init()

    self.active_zones = {}
    self.delta = 0

    Events:Subscribe(var("ShapeTriggerEnter"):get(), self, self.ShapeTriggerEnter)
    Events:Subscribe(var("ShapeTriggerExit"):get(), self, self.ShapeTriggerExit)
    Events:Subscribe(var("SecondTick"):get(), self, self.SecondTick)
    Events:Subscribe("Render", self, self.Render)
    
end

function GrenadeEffectZones:Render(args)

    self.delta = self.delta + args.delta
    for id, zone in pairs(self.active_zones) do
        if zone.timer:GetSeconds() >= zone.timeout then
            zone.trigger:Remove()
            self.active_zones[id] = nil
        end

        if zone.inside_zone and zone.type == "Slow" and not LocalPlayer:GetValue("InSafezone") then

            local entity = LocalPlayer
            if entity:InVehicle() then
                entity = entity:GetVehicle()
            end

            local velocity = entity:GetLinearVelocity()
            local magnitude = velocity:Length()

            if magnitude > 5 then
                velocity = velocity * 0.5
            end

            entity:SetLinearVelocity(velocity + Vector3(0, 1, 0))

        end
    end 
end


function GrenadeEffectZones:SecondTick()
    local inside_toxic_zone = false

    for id, zone in pairs(self.active_zones) do

        if zone.inside_zone then
            -- Player is currently inside this zone

            -- apply damage, etc
            if zone.type == "Toxic" and not inside_toxic_zone then
                Network:Send(var("items/PlayerInsideToxicGrenadeArea"):get(), {
                    attacker_id = zone.owner_id
                })
                inside_toxic_zone = true
            end
            
        end

    end
end

function GrenadeEffectZones:Add(args)

    local grenade_data = Grenade.Types[args.grenade_type]
    if not grenade_data then return end

    local zone = {
        trigger = ShapeTrigger.Create({
            position = args.position,
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
        type = args.type,
        owner_id = args.owner_id,
        inside_zone = false,
        timer = Timer(),
        timeout = args.timeout
    }

    self.active_zones[zone.trigger:GetId()] = zone

end

function GrenadeEffectZones:EnterZone(zone)
    zone.inside_zone = true

    if zone.type == "Fire" then
        Network:Send(var("items/PlayerInsideFireGrenadeArea"):get(), {
            attacker_id = zone.owner_id
        })
    end
end

function GrenadeEffectZones:ExitZone(zone)
    zone.inside_zone = false
end

function GrenadeEffectZones:ShapeTriggerEnter(args)
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if not self.active_zones[args.trigger:GetId()] then return end
    self:EnterZone(self.active_zones[args.trigger:GetId()])
end

function GrenadeEffectZones:ShapeTriggerExit(args)
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if not self.active_zones[args.trigger:GetId()] then return end
    self:ExitZone(self.active_zones[args.trigger:GetId()])
end

GrenadeEffectZones = GrenadeEffectZones()