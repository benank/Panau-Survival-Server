class 'cLocationManager'

function cLocationManager:__init()

    self.locations = {}

    Network:Subscribe("locations/SyncLocation", self, self.SyncLocation)

    Thread(function()
        while true do
            Timer.Sleep(1000)

            self:CheckForNearbyLocations()

        end
    end)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cLocationManager:CheckForNearbyLocations()

    local pos = Camera:GetPosition()

    for name, location in pairs(self.locations) do

        local range = location.radius * 2 + 2000
        local in_range = location.center:Distance(pos) < range

        if in_range and not location.spawned then
            location:SpawnObjects()
        elseif not in_range and location.spawned then
            location:RemoveAllObjects()
        end

    end

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