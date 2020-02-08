class 'cOutpostManager'

function cOutpostManager:__init()
	self.outposts_info = {}
	
	LocalPlayer:SetValue("InsideOutpost", false)
	self.localplayer_inside_outpost = false
	LocalPlayer:SetValue("CurrentOutpost", nil)
	self.current_outpost = "NotSet"
	
	self.ticks = 0
	Events:Subscribe("PostTick", self, self.PostTick)
	Network:Subscribe("OutpostsInfo", self, self.ReceiveOutpostsInfo)
end

function cOutpostManager:PostTick()
	self.ticks = self.ticks + 1
	
	if self.ticks > 81 then
		self.ticks = 0
		
		local plypos = LocalPlayer:GetPosition()
		local ply_cell_x, ply_cell_y = GetCell(plypos.x, plypos.z)
		
		local nearby_outposts = {}
		
		local adjacent_cells = {}
		local index = 1
		local cell = 0
		
		local tell_server = false
		local inside_outpost = false
		
		for x = ply_cell_x - 1, ply_cell_x + 1, 1 do
			for y = ply_cell_y - 1, ply_cell_y + 1, 1 do
				if self.outposts_cells[x] and self.outposts_cells[x][y] then -- we have data for this particular cell
					for name, outpost_data in pairs(self.outposts_cells[x][y]) do
						local distance = Vector3.Distance(plypos, outpost_data.basepos)
						if distance < outpost_data.radius then
							inside_outpost = true
							self.localplayer_inside_outpost = true
							
							if self.current_outpost ~= name then
								tell_server = true
							end
							self.current_outpost = name
							
							break
						end
					end
				end
			end
		end
		
		if not inside_outpost then
			if self.localplayer_inside_outpost then -- was in outpost on previous check
				Network:Send("PlayerExitOutpost", self.current_outpost)
			end
		
			self.localplayer_inside_outpost = false
			self.current_outpost = "NotSet"
		end
		
		LocalPlayer:SetValue("InsideOutpost", self.localplayer_inside_outpost)
		if self.localplayer_inside_outpost then
			LocalPlayer:SetValue("CurrentOutpost", self.outposts_info[self.current_outpost])
		end
		
		if tell_server then
			Network:Send("PlayerEnterOutpost", self.current_outpost)
		end
	end
end

function cOutpostManager:ReceiveOutpostsInfo(data)
	self.outposts_info = data
	
	self.outposts_cells = {}
	for name, outpost_data in pairs(data) do
		local cell_x, cell_y = GetCell(outpost_data.basepos.x, outpost_data.basepos.z)
		
		if not self.outposts_cells[cell_x] then
			self.outposts_cells[cell_x] = {}
		end
		
		if not self.outposts_cells[cell_x][cell_y] then
			self.outposts_cells[cell_x][cell_y] = {}
		end
			
		self.outposts_cells[cell_x][cell_y][name] = outpost_data
	end
	
	--Chat:Print("Received outpost data", Color.Green)
end

cOutpostManager = cOutpostManager()