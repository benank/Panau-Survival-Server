--[[class 'GrenadeEffectZones'

function GrenadeEffectZones:__init()

    self.active_zones = {}

    Events:Subscribe("ShapeTriggerEnter", self, self.ShapeTriggerEnter)
    Events:Subscribe("ShapeTriggerExit", self, self.ShapeTriggerExit)
    
end

function GrenadeEffectZones:Add(position, type)

    table.insert(self.active_zones, {
        trigger = ...,
        type = type,
        timer = Timer()
    })

end

function GrenadeEffectZones:ShapeTriggerEnter(trigger)

end

function GrenadeEffectZones:ShapeTriggerExit(trigger)

end

GrenadeEffectZones = GrenadeEffectZones()]]