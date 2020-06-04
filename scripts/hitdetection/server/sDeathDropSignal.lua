Events:Subscribe("PlayerKilled", function(args)
    if args.killer then

        -- Player was killed by someone else

        local pos = args.player:GetPosition()

        Network:Send(args.player, "HitDetection/DeathDropSignal", {position = pos})
        Network:SendNearby(args.player, "HitDetection/DeathDropSignal", {position = pos})

    end
end)