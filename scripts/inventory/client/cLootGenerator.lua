class 'cLootGenerator'


function cLootGenerator:__init()
    self.loot_generators = DynamicCellTable()
	
	self.disabled = true

    Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
end

function cLootGenerator:FullfillQuotas(x, y, quotas)
	if not self.loot_generators:HasValue(x, y) then
		--local cell_loot_generator = cCellLootGenerator(x, y, quotas)
		--self.loot_generators:AddEntry(x, y, cell_loot_generator)
		
		--debug("Created Loot Generator for " .. tostring(x) .. " " .. tostring(y))
	else
		--debug("Loot Generator for " .. tostring(x) .. " " .. tostring(y) .. " already exists!!!")
	end
end

function cLootGenerator:GetObjectDensityOfCell(x, y)
	
end

function cLootGenerator:LocalPlayerChat(args)
	if args.text == "/getcell" then
		local x, y = GetCell(Camera:GetPosition())
		
		debug("x: " .. tostring(x) .. "   y: " .. tostring(y))
		
		local adjacents = GetAdjacentCells(x, y)
		
		for index, adjacent in ipairs(adjacents) do
			print(adjacent.x, adjacent.y)
		end
		print("\n")
	end
end

function cLootGenerator:Render(args)
	for cell_x, cell_y, loot_generator in dynamic_cell_table(self.loot_generators) do
		loot_generator:Update()
	end
	
	if debug_timer:GetMilliseconds() > 7500 then
		debug_timer:Restart()
		
		for x, y, generator in dynamic_cell_table(self.loot_generators) do
			generator:Remove()
		end
		
		if not self.disabled then
			self:RaycastAdjacents()
		end
	end
end

function cLootGenerator:RaycastAdjacents()
	local x, y = GetCell(LocalPlayer:GetPosition())
	local adjacents = GetAdjacentCells(x, y)
	
	_raycasts = {}
	self.loot_generators = DynamicCellTable()
		
	for index, adjacent in ipairs(adjacents) do
		print("adjacent#", index, adjacent.x, adjacent.y)
		local cell_loot_generator = cCellLootGenerator(adjacent.x, adjacent.y, {})
		self.loot_generators:AddEntry(adjacent.x, adjacent.y, cell_loot_generator)
	end
	print("\n")
	
end

debug_timer = Timer()


cLootGenerator = cLootGenerator()