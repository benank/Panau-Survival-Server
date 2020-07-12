class 'sBuildCommands'

function sBuildCommands:__init()


    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Network:Subscribe("BuildTools/SetCurrentObject", self, self.SetCurrentObject)
    Network:Subscribe("BuildTools/PlaceObject", self, self.PlaceObject)
    Network:Subscribe("BuildTools/DeleteObject", self, self.DeleteObject)

end

function sBuildCommands:DeleteObject(args, player)

    local location_name = player:GetValue("Build_Location")

    local location = sLocationManager.locations[location_name]
    if not location then return end

    if not args.object_id then return end

    location:RemoveObject(args)

end

function sBuildCommands:PlaceObject(args, player)

    local location_name = player:GetValue("Build_Location")

    local location = sLocationManager.locations[location_name]
    if not location then return end

    local current_object = player:GetValue("CurrentObject")

    local object_data = 
    {
        model = current_object.model,
        collision = current_object.collision,
        position = args.position,
        angle = args.angle,
        object_id = args.object_id
    }

    location:AddObject(object_data)

end


function sBuildCommands:SetCurrentObject(args, player)
    player:SetNetworkValue("CurrentObject", {
        model = args.model,
        collision = args.collision
    })
end

function sBuildCommands:PlayerChat(args)

    local words = args.text:split(" ")

    if words[1] == "/setobject" then

        local model = words[2]
        local collision = words[3]

        if not model or not collision then
            Chat:Send(args.player, "You must specify both a model and collision!", Color.Red)
            return
        end

        args.player:SetNetworkValue("CurrentObject", {
            model = model,
            collision = collision
        })

        Chat:Send(args.player, string.format("Set current object model to %s and collision to %s", 
            model, collision), Color(0, 255, 0))

        return

    end

    if words[1] ~= "/location" then return end

    local current_location = args.player:GetValue("Build_Location")

    if words[2] == "create" then
        -- Create a new location if it does not exist

        local radius = tonumber(words[3])

        if not radius then
            Chat:Send(args.player, "You must specify a location radius!", Color.Red)
            return
        end

        local name = args.text:gsub(words[1], ""):gsub(words[2], ""):gsub(words[3], ""):trim()

        if not name then
            Chat:Send(args.player, "You must specify a location name!", Color.Red)
            return
        end

        if radius <= 0 then
            Chat:Send(args.player, "You must specify a location radius greater than 0!", Color.Red)
            return
        end

        if sLocationManager.locations[string.lower(name)] then
            Chat:Send(args.player, "This location has already been created!", Color.Red)
            return
        end

        -- create new location, assign it to player
        local location = sLocationManager:AddLocation({
            name = name,
            radius = radius,
            center = args.player:GetPosition(),
            objects = {}
        })

        -- Save location to file for the first time
        sLocationLoader:SaveLocation(location)

        args.player:SetNetworkValue("Build_Location", string.lower(name))

    elseif words[2] == "build" then
        -- Start building at an existing location

        local name = args.text:gsub(words[1], ""):gsub(words[2], ""):trim()

        if not name then
            Chat:Send(args.player, "You must specify a location name!", Color.Red)
            return
        end

        if not sLocationManager.locations[string.lower(name)] then
            Chat:Send(args.player, "This location does not exist! Maybe try creating it first?", Color.Red)
            return
        end

        -- set current location to specified one
        args.player:SetNetworkValue("Build_Location", string.lower(name))

        Chat:Send(args.player, string.format("Now building at %s", name), Color(0, 255, 0))

    elseif words[2] == "save" then
        -- Save player's current location

        if not current_location then
            Chat:Send(args.player, "You must be building a location to save!", Color.Red)
            return
        end

        if not sLocationManager.locations[current_location] then
            Chat:Send(args.player, "Your current location does not exist!", Color.Red)
            return
        end

        sLocationLoader:SaveLocation(sLocationManager.locations[current_location])

    elseif words[2] == "tp" then

        local name = args.text:gsub(words[1], ""):gsub(words[2], ""):trim()

        if not name then
            Chat:Send(args.player, "You must specify a location name!", Color.Red)
            return
        end

        local location = sLocationManager.locations[string.lower(name)]

        if not location then
            Chat:Send(args.player, "This location does not exist! Maybe try creating it first?", Color.Red)
            return
        end

        args.player:SetPosition(location.center + Vector3.Up * 500)

        Chat:Send(args.player, string.format("Teleported to %s", name), Color(0, 255, 0))

    end


end