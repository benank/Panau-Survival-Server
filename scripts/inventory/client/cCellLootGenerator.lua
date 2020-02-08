class 'cCellLootGenerator'
-- eat memory, but finish work and destroy this instance quickly

function cCellLootGenerator:__init(x, y, tier_quotas)
	self.x = x
	self.y = y
	self.tier_quotas = tier_quotas
	self.color = Color(randy(0, 255, x + 1284 * y), randy(0, 255, x / y + x), randy(0, 255, x + y / y))
	
	self.raycasted = false
	
	
	self.flatness = nil
	
	self.object_density = nil
	self.build_objects = {}
end

function cCellLootGenerator:Update() -- Render 
	
	if not self.raycasted then
		self.raycasted = true
		
		-- cell corners
		print("raycasting", self.x, self.y)
		local x_start, x_stop, z_start, z_stop = GetCellCorners(self.x, self.y)
		
		--print(x_start, x_stop, z_start, z_stop)
		
		for x = x_start, x_stop, 16 do
			for z = z_start, z_stop, 16 do
				--print(x, z)
				local pos = Vector3(x, GetTerrainHeight(Vector2(x, z)), z) + Vector3(0, 40, 0)
				
				local raycast = Raycast(pos, Vector3.Down, 0, 300)
				raycast.color = self.color
			end
		end
	end
	
	local center = GetCenterOfCell(self.x, self.y) + Vector3(0, 50, 0)
	Render:FillCircle(Render:WorldToScreen(center), 5, self.color)
	
	
end

function cCellLootGenerator:CalculateFlatness()
	for x = x_start, x_stop, 16 do
		for z = z_start, z_stop, 16 do
			--print(x, z)
			local pos = Vector3(x, GetTerrainHeight(Vector2(x, z)), z) + Vector3(0, 40, 0)
				
			local raycast = Raycast(pos, Vector3.Down, 0, 300)
			raycast.color = self.color
		end
	end
end

function cCellLootGenerator:Remove()
	
end

