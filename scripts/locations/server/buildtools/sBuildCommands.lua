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

        if not words[3] then
            Chat:Send(args.player, "You must specify a location name!", Color.Red)
            return
        end

        if not words[4] then
            Chat:Send(args.player, "You must specify a location radius!", Color.Red)
            return
        end

        local name = string.lower(words[3])
        local radius = tonumber(words[4])

        if radius <= 0 then
            Chat:Send(args.player, "You must specify a location radius greater than 0!", Color.Red)
            return
        end

        -- create new location, assign it to player
        sLocationManager:AddLocation({
            name = name,
            radius = radius,
            center = args.player:GetCameraPosition()
        })

        args.player:SetNetworkValue("Build_Location", name)

    elseif words[2] == "build" then
        -- Start building at an existing location

        if not words[3] then
            Chat:Send(args.player, "You must specify a location name!", Color.Red)
            return
        end

        -- check if location exists
        local name = string.lower(words[3])

        if not sLocationManager.locations[name] then
            Chat:Send(args.player, "This location does not exist! Maybe try creating it first?", Color.Red)
            return
        end

        -- set current location to specified one
        args.player:SetNetworkValue("Build_Location", name)

        Chat:Send(args.player, string.format("Now building at %s", words[3]), Color(0, 255, 0))

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

        sLocationManager.locations[current_location]:Save()

    end


end