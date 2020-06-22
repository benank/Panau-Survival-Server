class 'sLocationLoader'

local json = require('json')
local encode, decode = json.encode, json.decode

function sLocationLoader:__init()

    self.location_dir = "location_data"

    self.locations_to_load = 
    {
        "test"
    }
    
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)

end

function sLocationLoader:SaveLocation(location)

    local serialized = encode({
        name = location.name,
        radius = location.radius,
        center = location.center,
        objects = location.objects
    })

    local file = io.open(self:GetFilePath(location.name))

    file:write(serialized)

    file:close()

    Chat:Broadcast(string.format("Location %s saved successfully! (%d objects)", location.name, count_table(location.objects)), Color(0, 255, 0))

end

function sLocationLoader:ModuleLoad()

    -- Load all locations
    self:LoadAllLocations(self.locations_to_load)

end

function sLocationLoader:GetFilePath(filename)
    return string.format("./%s/%s.json", self.location_dir, filename)
end

function sLocationLoader:LoadAllLocations(filepaths)
    
    for _, filename in ipairs(filepaths) do
        local path_name = self:GetFilePath(filename)
        print(path_name)

    end

end

sLocationLoader = sLocationLoader()