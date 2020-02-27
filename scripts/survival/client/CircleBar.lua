class 'CircleBar'

function CircleBar:__init(pos, size, data) -- Make a circle bar with as many sections as you like

	--[[
	data is a table of tables
	each one of these tables contains max_amount (float), amount (float), and color (color)
	the amounts from each of the tables add up to make a total amount
	and this determines how much of the circle each amount gets
	then the circles are drawn
	--]]

	self.pos = pos
	self.size = size
	self.data = data

	self.resolution = self.size * 10
	self.inner_radius = 0
	self.background_color = Color(0,0,0,120)
	self.outline_enabled = false
	self.visible = true -- Set to false to disable rendering
	
	self:Update()
	
end

function CircleBar:Render(args)

	if not self.visible then return end

	local t = Transform2()
	t:Translate(self.pos)
	Render:SetTransform(t)
	
	if self.model then
		self.model:Draw()
	end
	
	if self.outline_enabled then
		Render:DrawCircle(Vector2(), self.size * self.inner_radius, Color.Black)
		Render:DrawCircle(Vector2(), self.size, Color.Black)
	end
	
	Render:ResetTransform()
	
end

function CircleBar:Update() -- Updates all information from self.data including model

	self.max = 0 -- Maximum value of the circle
	
	for _, data in ipairs(self.data) do
		self.max = self.max + data.max_amount -- Add up all the maxes
	end
	
	local vertices = {}
		
	local current_percent = 0
	
	local inner_radius = self.size * self.inner_radius
	local outer_radius = self.size * 1
		
	for _, data in ipairs(self.data) do
		local percent = math.ceil((data.max_amount / self.max) * 100) / 100 -- Percent of the circle it will take up
		
		local coords_inner = self:GetCircleCoordinates(Vector2(), inner_radius, self.resolution, current_percent, current_percent + percent)
		local coords_outer = self:GetCircleCoordinates(Vector2(), outer_radius, self.resolution, current_percent, current_percent + percent)
		
		for i = 1, #coords_inner do
			
			local color = data.color
			if (i / #coords_inner) <= (1 - data.amount / data.max_amount) then
				color = self.background_color
			end
			
			-- instead of just [i], do [#coords_inner - i + 1] to reverse the direction of the bar
			table.insert(vertices, Vertex(coords_inner[#coords_inner - i + 1], color))
			table.insert(vertices, Vertex(coords_outer[#coords_outer - i + 1], color))
			
		end
		
		current_percent = current_percent + percent
		
	end
	
	
	if not self.model then
		self.model = Model.Create(vertices)
		self.model:SetTopology(Topology.TriangleStrip)
		self.model:Set2D(true)
	else
		self.model:Update(vertices)
	end


end

function CircleBar:GetCircleCoordinates(position, radius, resolution, start_percent, final_percent)

    local coords = {}

    for theta = 0 + math.pi * 2 * (start_percent or 0), 2 * math.pi * (final_percent or 1), 2 * math.pi / resolution do
        local x = radius * math.sin(theta)
        local y = radius * math.cos(theta)
        local point = position - Vector2(-x,y)
        table.insert(coords, point)
    end

    return coords

end
