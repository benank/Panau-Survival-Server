function SendWaypoint(args)
    if not (IsTest or IsStaff(player)) then return end
	if args.key == string.byte("P") and not LocalPlayer:GetValue("Talking") then
		
		if Waypoint:GetPosition() ~= Vector3(0, 0, 0) then
			local wp = Waypoint:GetPosition()
			wp.y = wp.y + 50
			Network:Send("ToWaypoint", {pos = wp})
			Waypoint:Remove()
		end
	end
end
Events:Subscribe("KeyDown", SendWaypoint)