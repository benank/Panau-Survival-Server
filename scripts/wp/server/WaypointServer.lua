function TeleportToWP(args, player)
    if not (IsTest or IsAdmin(player)) then return end
	player:SetPosition(args.pos)
end
Network:Subscribe("ToWaypoint", TeleportToWP)