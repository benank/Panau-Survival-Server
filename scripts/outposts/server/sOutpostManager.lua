class 'sOutpostManager'

function sOutpostManager:__init()
	self.outposts = {}
	self.outpost_info = {}
	
	self:LoadAllOutposts()
	
	for name, outpost_data in pairs(self.outposts) do
		self.outpost_info[name] = {}
		self.outpost_info[name].basepos = outpost_data.basepos
		self.outpost_info[name].radius = outpost_data.radius
	end
	
	self.ticks = 0
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
	Events:Subscribe("PlayerChat", self, self.PlayerChat)
	
	Network:Subscribe("PlayerEnterOutpost", self, self.PlayerEnterOutpost)
	Network:Subscribe("PlayerExitOutpost", self, self.PlayerExitOutpost)
end

function sOutpostManager:PreTick()
	self.ticks = self.ticks + 1
	
	if self.ticks > 7 then
		self.ticks = 0
		
		for name, outpost in pairs(self.outposts) do
			outpost:Update()
		end
	end
end

function sOutpostManager:ClientModuleLoad(args)
	Network:Send(args.player, "OutpostsInfo", self.outpost_info)
end

function sOutpostManager:LoadAllOutposts()
	self:LoadOutpost("skull")
end

function sOutpostManager:PlayerEnterOutpost(outpost, player)
	player:SendChatMessage("You entered " .. outpost, Color.Orange)
	print(player:GetName() .. " entered " .. outpost)
	
	local outpost_class = self.outposts[outpost]
	if outpost_class then
		outpost_class:PlayerEnter(player)
	end
	
	player:SetValue("CurrentOutpost", outpost)
end

function sOutpostManager:PlayerExitOutpost(outpost, player)
	player:SendChatMessage("You exited " .. outpost, Color.Orange)
	print(player:GetName() .. " exited " .. outpost)
	
	local outpost_class = self.outposts[outpost]
	if outpost_class then
		outpost_class:PlayerExit(player)
	end
	
	player:SetValue("CurrentOutpost", nil)
end

function sOutpostManager:LoadOutpost(name)
	local file = io.open("outpost-" .. name .. ".txt", "r")
	
	if file ~= nil then -- file might not exist
		local lines = {}
		local line_count = 1
		for line in file:lines() do 
			lines[line_count] = line
			line_count = line_count + 1
		end
		
		local tokens = lines[1]:split(" ")
		local basepos = Vector3(tonumber(tokens[1]), tonumber(tokens[2]), tonumber(tokens[3]))
		print("basepos", basepos)
		
		local radius = tonumber(lines[2])
		print("radius", radius)
		
		-- read ai maneuvers
		self.reading_heli_maneuver = false
		self.heli_index = 0
		local ai_spawnpoints = {helis = {}, boats = {}, planes = {}, actors = {}}
		
		for i = 3, line_count - 1 do
			local line = lines[i]
			
			if line == "StartHeliManeuver" then
				self.reading_heli_maneuver = true
				self.heli_index = self.heli_index + 1
				ai_spawnpoints.helis[self.heli_index] = {}
				i = i + 1
				line = lines[i]
			elseif line == "EndHeliManeuver" then
				self.reading_heli_maneuver = false
			end
			
			if self.reading_heli_maneuver then
				local tokens = line:split(" ")
				
				local pos_tokens = tokens[1]:split(",")
				local pos = Vector3(tonumber(pos_tokens[1]), tonumber(pos_tokens[2]), tonumber(pos_tokens[3]))
				
				local ang_tokens = tokens[2]:split(",")
				local ang = Angle(tonumber(ang_tokens[1]), tonumber(ang_tokens[2]), tonumber(ang_tokens[3]), tonumber(ang_tokens[4]))
				
				table.insert(ai_spawnpoints.helis[self.heli_index], {pos, ang})
			end
		end
		
		local outpost = sOutpost(name, basepos, radius, ai_spawnpoints)
		self.outposts[name] = outpost
	else
		print("Tried to load outpost that does not exist")
	end
end

function sOutpostManager:PlayerQuit(args)
	local player_current_outpost = args.player:GetValue("CurrentOutpost") -- not a network value
	
	if player_current_outpost and self.outposts[player_current_outpost] then
		local outpost = self.outposts[player_current_outpost]
		outpost:PlayerExit(args.player)
	end
end

function sOutpostManager:PlayerChat(args)
	
	if args.text == "/loadalloutposts" then
		self:LoadAllOutposts()
	end
	
end

function sOutpostManager:ModuleUnload()
	
end

sOutpostManager = sOutpostManager()