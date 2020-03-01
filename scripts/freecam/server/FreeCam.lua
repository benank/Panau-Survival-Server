
class("FreeCamManager")

function FreeCamManager:__init()
	local files = {Config.trajectoryPath, Config.positionsPath}
	for i, v in ipairs(files) do
		local file = io.open(v, "r")
		if file == nil then
			file = io.open(v, "w")
		end
		file:close()
	end
	Network:Subscribe("FreeCamTP", self, self.TeleportPlayer)
	Network:Subscribe("FreeCamStore", self, self.StoreTrajectory)

	-- Set default permissions from whitelist
	Events:Subscribe("ModuleLoad", self, self.SendPermissionAll)
	Events:Subscribe("ModulesLoad", self, self.SendPermissionAll)
	Events:Subscribe("PlayerJoin", self, self.SendPermission)

	-- Notice other modules on serverside when cam has changed
	Network:Subscribe("FreeCamChange", function(args, client)
			if args.active == nil then return end
			args.player = client
			Events:Fire("FreeCamChange", args)
		end)

	-- Forward permissions to FreeCam client
	Events:Subscribe("FreeCam", function(args)
			if args.player == nil then return end
			local perm = args.perm
			if args.restore then
				perm = FreeCamManager.CheckWhiteList(args.player)
			end
			Network:Send(args.player, "FreeCam",
								{["perm"] = perm,
								 ["active"] = args.active})
		end)
end


function FreeCamManager:TeleportPlayer(args, client)
	if not Config.teleport or args.pos == nil then return end
	if client:InVehicle() then
		client:GetVehicle():SetPosition(args.pos)
		client:GetVehicle():SetPosition(args.angle)
	else
		client:SetPosition(args.pos)
		client:SetAngle(args.angle)
	end
end

function FreeCamManager:SendPermissionAll(args)
	for player in Server:GetPlayers() do

		if FreeCamManager.CheckWhiteList(player) then
			Network:Send(player, "FreeCam", {["perm"] = true})
		end
	end
end

function FreeCamManager:SendPermission(args)
	local player = args.player

	if FreeCamManager.CheckWhiteList(player) then
		Network:Send(player, "FreeCam", {["perm"] = true})
	end
end

function FreeCamManager.CheckWhiteList(player)
	local perm1 = table.find(WhiteList, player:GetSteamId().id)
	local perm2 = table.find(WhiteList, player:GetSteamId().string)
	if perm1 ~= nil or perm2 ~= nil then
		return true
	else
		return false
	end
end

---------- TRAJECTORY MANAGEMENT -----------
function FreeCamManager:StoreTrajectory(args, client)
	if not FreeCamManager.CheckWhiteList(client) then
		client:SendChatMessage(string.format("%s Error: no permission to save trajectories",
								Config.name), Config.colorError)
		return
	end
	local name = nil
	if args.name ~= nil then
		-- Only allow letters and digits
		name = args.name:gsub("[^%a%d]", "")
	end
	if args.type == nil or name == nil then
		client:SendChatMessage(string.format("%s Usage: /freecam <save/load/delete> <trajectory_name>",
								Config.name), Config.color)
		return
	end
	if args.type == "save" then
		if args.trajectory == nil and args.position == nil then
			client:SendChatMessage(string.format("%s No trajectory found!", Config.name), Config.colorError)
			return
		end
		local fileName = nil
		local typeName = nil
		if args.trajectory then
			fileName = Config.trajectoryPath
			typeName = "Trajectory"
		elseif args.position then
			fileName = Config.positionsPath
			typeName = "Position"
		end

		local found = false
		for line in io.lines(fileName) do
			local exists = string.find(line, "NAME%(" .. name .. "%)")
			local exists2 = string.find(line, "T " .. name .. ",")
			if exists or exists2 then
				client:SendChatMessage(string.format("%s %s with this name already exists!",
								Config.name, typeName), Config.colorError)
				found = true
			end
		end
		if found then return end

		file = io.open(fileName, "a")
		if args.position then
			-- Save position
			local pos = args.position
			file:write(string.format("T %s, %f, %f, %f\n",
						name,
						pos.x, pos.y, pos.z)
					)
			client:SendChatMessage(string.format("%s Saved position '%s'!",
								Config.name, name), Config.color)
		else
			-- Save trajectory
			file:write(string.format("NAME(%s)", name))
			for k, v in ipairs(args.trajectory) do
				file:write(string.format("W%f,%f,%f %f,%f,%f",
													v.pos.x,
													v.pos.y,
													v.pos.z,
													v.angle.yaw,
													v.angle.pitch,
													v.angle.roll))
			end
			file:write("\n")
			client:SendChatMessage(string.format("%s Saved trajectory '%s' with %d waypoints!",
								Config.name, name, #args.trajectory), Config.color)
		end
		file:close()
	elseif args.type == "load" then		
		local found = false
		for line in io.lines(Config.trajectoryPath) do
			local exists = string.find(line, "NAME%(" .. args.name .. "%)")
			if exists then
				local trajectory = {}
				line = string.gsub(line, "NAME%(%a+%)", "")
				line = line:split("W")
				table.remove(line, 1)
				for i, v in ipairs(line) do
					-- Waypoint
					local waypoint = v:split(" ")
					local pos = waypoint[1]:split(",")
					local angle = waypoint[2]:split(",")
					pos = Vector3(tonumber(pos[1]), tonumber(pos[2]), tonumber(pos[3]))
					angle = Angle(tonumber(angle[1]), tonumber(angle[2]), tonumber(angle[3]))
					table.insert(trajectory, {["pos"] = pos,
											  ["angle"] = angle})
				end

				Network:Send(client, "FreeCamStore", {["type"] = "load",
													  ["name"] = args.name,
													  ["trajectory"] = trajectory})
				found = true
			end
		end

		if not found then
			client:SendChatMessage(string.format("%s Error: Trajectory '%s' not found",
									Config.name, args.name), Config.colorError)
		end
	elseif args.type == "delete" then		
		local content = {}
		local found = false
		for line in io.lines(Config.trajectoryPath) do
			local remove = string.find(line, "NAME%(" .. args.name .. "%)")
			if not remove then
				content[#content+1] = line
			else
				found = true
			end
		end

		local file = io.open(Config.trajectoryPath, "w+")
		for i, v in ipairs(content) do
			file:write(v .. "\n")
		end
		file:close()

		if found then			
			client:SendChatMessage(string.format("%s Removed trajectory '%s'",
				Config.name, args.name), Config.color)
		else
			client:SendChatMessage(string.format("%s Error: Trajectory '%s' not found",
				Config.name, args.name), Config.colorError)
		end
	else
		print(args.type)
	end

end

freeCamManager = FreeCamManager()