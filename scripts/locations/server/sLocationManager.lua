class 'sLocationManager'

function sLocationManager:__init()

    self.locations = {}

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

end

function sLocationManager:ClientModuleLoad(args)
    
    -- TODO: add network send limits and split into multiple sends

    for name, location in pairs(self.locations) do
        Network:Send(args.player, "locations/SyncLocation", location:GetSyncData())
    end

end

function sLocationManager:AddLocation(data)
    local location = sLocation(data)
    self.locations[string.lower(data.name)] = location
    
    return location

end

sLocationManager = sLocationManager()