class 'sBuildCommands'

function sBuildCommands:__init()


    Events:Subscribe("PlayerChat", self, self.PlayerChat)

end

function sBuildCommands:PlayerChat(args)

    local words = args.text:split(" ")

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

    end


end