function TeleportToWP(args, player)
    if not (IsTest or IsStaff(player)) then return end
	player:SetPosition(args.pos)
end
Network:Subscribe("ToWaypoint", TeleportToWP)