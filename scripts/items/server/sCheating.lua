-- TODO: make this more robust
Network:Subscribe("items/Cheating", function(args, player)
    Events:Fire("KickPlayer", {
        player = player,
        reason = args.reason,
        p_reason = args.p_reason
    })
end)