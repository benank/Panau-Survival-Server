class 'sLocationManager'

function sLocationManager:__init()

    self.locations = {}

end

function sLocationManager:AddLocation(data)
    local location = sLocation(data)
    self.locations[string.lower(data.name)] = location
    
    return location

end

sLocationManager = sLocationManager()