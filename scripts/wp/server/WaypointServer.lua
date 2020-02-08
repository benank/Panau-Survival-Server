function TeleportToWP(args, player)
	player:SetPosition(args.pos)
end
Network:Subscribe("ToWaypoint", TeleportToWP)