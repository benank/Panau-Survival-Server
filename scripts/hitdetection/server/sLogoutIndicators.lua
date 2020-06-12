Events:Subscribe("PlayerQuit", function(args)
    Network:Broadcast("HitDetection/PlayerQuit", {
        name = args.player:GetName(),
        position = args.player:GetPosition()
    })
end)