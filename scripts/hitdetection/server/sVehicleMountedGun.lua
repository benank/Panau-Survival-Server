Events:Subscribe("PlayerEnterMG", function(args)
    args.player:SetNetworkValue("VehicleMG", args.vehicle)
end)

Events:Subscribe("PlayerExitMG", function(args)
    args.player:SetNetworkValue("VehicleMG", nil)
end)