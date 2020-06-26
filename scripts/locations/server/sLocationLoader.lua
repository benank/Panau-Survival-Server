class 'sLocationLoader'

local json = require('json')
local encode, decode = json.encode, json.decode

function sLocationLoader:__init()

    self.location_dir = "location_data"

    self.locations_to_load = 
    {
        "triple"
    }
    
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)

end

function sLocationLoader:SaveLocation(location)

    if not location then
        Chat:Broadcast("No location found", Color.Red)
        return
    end

    local objects_serialized = {}

    for index, object_data in pairs(location.objects) do
        objects_serialized[index] = self:SerializeObjectData(object_data)
    end

    local serialized = encode({
        name = location.name,
        radius = location.radius,
        center = self:SerializeVector(location.center),
        objects = objects_serialized
    }, {indent = "\t"})

    local file = io.open(self:GetFilePath(location.name), "w")

    if not file then
        error(string.format("Failed to get file %s", self:GetFilePath(location.name)))
    end

    file:write(serialized)

    file:close()

    print(string.format("Location %s saved successfully! (%d objects)", location.name, count_table(location.objects)))
    Chat:Broadcast(string.format("Location %s saved successfully! (%d objects)", location.name, count_table(location.objects)), Color(0, 255, 0))

end

function sLocationLoader:ModuleLoad()

    -- Load all locations
    self:LoadAllLocations(self.locations_to_load)

end

function sLocationLoader:GetFilePath(filename)
    return string.format("%s/%s.json", self.location_dir, string.lower(filename))
end

function sLocationLoader:SerializeObjectData(data)
    return {
        position = self:SerializeVector(data.position),
        angle = tostring(self:SerializeAngle(data.angle)),
        model = data.model,
        collision = data.collision
    }
end

function sLocationLoader:DeserializeObjectData(data)
    return {
        position = self:DeserializeVector(data.position),
        angle = self:DeserializeAngle(data.angle),
        model = data.model,
        collision = data.collision
    }
end

function sLocationLoader:SerializeVector(vec)
    return {
        ["x"] = math.round(vec.x, 6),
        ["y"] = math.round(vec.y, 6),
        ["z"] = math.round(vec.z, 6)
    }
end

function sLocationLoader:DeserializeVector(vec)
    return Vector3(tonumber(vec["x"]), tonumber(vec["y"]), tonumber(vec["z"]))
end

function sLocationLoader:SerializeAngle(ang)
    return math.round(ang.x, 6) .. "," .. math.round(ang.y, 6) .. "," .. math.round(ang.z, 6) .. "," .. math.round(ang.w, 6)
end

function sLocationLoader:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

function sLocationLoader:LoadAllLocations(filepaths)
    
    for _, filename in ipairs(filepaths) do
        local path_name = self:GetFilePath(filename)

        local file = io.open(path_name, "r")

        if not file then
            print(string.format("Could not load file %s", path_name))
        else

            local content = file:read("*a")
            file:close()

            local data = decode(content)
            data.center = self:DeserializeVector(data.center)

            for index, object_data in pairs(data.objects) do
                data.objects[index] = self:DeserializeObjectData(object_data)
            end

            print(string.format("Loaded location %s (%d objects)", data.name, count_table(data.objects)))

            sLocationManager:AddLocation(data)

        end

    end

end

sLocationLoader = sLocationLoader()