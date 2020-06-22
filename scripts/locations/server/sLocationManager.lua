class 'sLocationManager'

function sLocationManager:__init()

    self.locations = {}

end

function sLocationManager:AddLocation(data)
    self.locations[data.name] = sLocation(data)
end

sLocationManager = sLocationManager()