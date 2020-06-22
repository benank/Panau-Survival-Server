class 'cLocationManager'

function cLocationManager:__init()

    self.locations = {}

    Network:Subscribe("locations/SyncLocation", self, self.SyncLocation)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cLocationManager:SyncLocation(args)
    self.locations[args.name] = cLocation(args)
end

function cLocationManager:ModuleUnload()
    for name, location in pairs(self.locations) do
        location:Remove()
    end
end

cLocationManager = cLocationManager()