Events:Subscribe("PlayerJoin", function(args)

    args.player:SetValue("load/StreamDistance", args.player:GetStreamDistance())
    args.player:SetValue("Loading", true)
    args.player:SetStreamDistance(0)
    args.player:SetEnabled(false)

end)

Network:Subscribe("LoadStatus", function(args, player)

    if args and args.status == "done" then

        player:SetStreamDistance(player:GetValue("load/StreamDistance"))
        player:SetValue("Loading", false)
        player:SetEnabled(true)

    else

        player:SetValue("Loading", true)
        player:SetStreamDistance(0)
        player:SetEnabled(false)
    
    end

    Events:Fire("LoadStatus", {player = player, status = not (args and args.status == "done")})

end)
