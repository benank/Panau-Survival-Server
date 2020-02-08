building_outposts = {}

Events:Subscribe("PlayerChat", function(args)
	
	if args.text == "/recordoutpost" then
		args.player:SetValue("RecordingOutpost", true)
		building_outposts[tostring(args.player:GetSteamId().id)] = {}
		args.player:SendChatMessage("Started recording outpost", Color.LawnGreen)
		return false
	end
	
	if args.text == "/setoutpostbasepos" then
		if not validateRecording(args.player) then return false end
		
		local outpost_data = building_outposts[tostring(args.player:GetSteamId().id)]
		outpost_data.basepos = args.player:GetPosition()
		SyncValue("basepos", outpost_data.basepos, args.player)
		args.player:SendChatMessage("Set outpost basepos", Color.LawnGreen)
		return false
	end
	
	if args.text == "/setoutpostradius" then
		if not validateRecording(args.player) then return false end
		
		local outpost_data = building_outposts[tostring(args.player:GetSteamId().id)]
		outpost_data.radius = Vector3.Distance(outpost_data.basepos, args.player:GetPosition())
		SyncValue("radius", outpost_data.radius, args.player)
		args.player:SendChatMessage("Set outpost radius type(/renderradius to render it)", Color.LawnGreen)
		return false
	end
	
	if args.text:find("/exportoutpost") then
		if not validateRecording(args.player) then return false end
		local outpost_data = building_outposts[tostring(args.player:GetSteamId().id)]
		
		local name = string.sub(args.text, 16)
		WriteOutpostToFile(name, outpost_data)
		
		args.player:SendChatMessage("Saved outpost named " .. name, Color.LawnGreen)
		
		return false
	end
	
end)

function SyncValue(name, value, player)
	Network:Send(player, "OutpostBuildSync", {name = name, value = value})
end

function validateRecording(player)
	local recording = player:GetValue("RecordingOutpost")
	if not recording then
		player:SendChatMessage("You are not recording", Color.Red)
		return false
	end
	return true
end

Network:Subscribe("ReloadOutpostFromClient", function(outpost_data, player)
	building_outposts[tostring(player:GetSteamId().id)] = outpost_data
end)

Network:Subscribe("UpdateOutpostAIManeuvers", function(maneuvers, player)
	building_outposts[tostring(player:GetSteamId().id)].ai_maneuvers = maneuvers
	SyncValue("ai_maneuvers", maneuvers, player)
	player:SendChatMessage("Added Maneuver to outpost", Color.LawnGreen)
end)

function WriteOutpostToFile(name, outpost_data)
	local file = io.open("outpost-" .. tostring(name) .. ".txt", "w")
	
	-- write basepos as first line
	file:write(tostring(math.round(outpost_data.basepos.x, 3)) .. " " .. tostring(math.round(outpost_data.basepos.y, 3)) .. " " .. tostring(math.round(outpost_data.basepos.z, 3)), "\n")
	
	-- write radius as second line
	file:write(tostring(math.round(outpost_data.radius, 1)), "\n")
	
	print(outpost_data.ai_maneuvers)
	print(outpost_data.ai_maneuvers.helis)
	
	-- write heli maneuvers to file
	if outpost_data.ai_maneuvers and outpost_data.ai_maneuvers.helis then
		-- signal beginning of heli data
		--file:write("BeginHeliData", "\n")
	
		for index, heli_data in pairs(outpost_data.ai_maneuvers.helis) do -- [1] is pos, [2] is heli angle
			
			-- indicate new heli
			file:write("StartHeliManeuver", "\n")
			
			for frame, frame_data in ipairs(heli_data) do
				local pos = frame_data[1]
				local heli_ang = frame_data[2]
				
				-- write position and angle as x,y,z x,y,z,w
				file:write(tostring(math.round(pos.x, 3)) .. "," .. tostring(math.round(pos.y, 3)) .. "," .. tostring(math.round(pos.z, 3)) .. " " .. tostring(math.round(heli_ang.x, 6)) .. "," .. tostring(math.round(heli_ang.y, 6)) .. "," .. tostring(math.round(heli_ang.z, 6)) .. "," .. tostring(math.round(heli_ang.w, 6)), "\n")
			end
			
			file:write("EndHeliManeuver", "\n")
		end
		
		--file:write("EndHeliData", "\n")
	end
	
	file:close()
	
	
end

