Network:Subscribe("spawn/PlayerSetPosition", function(args)
    Events:Fire("loader/PlayerPositionSet")
end)