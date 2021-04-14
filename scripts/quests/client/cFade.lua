class 'Fade'

function Fade:__init(pos, size, color, rotation, endfade)

	self.model = nil
	self.c = color or Color(255,255,255)
	
	self.endfade = endfade or nil
	self.rotation = rotation or nil
	self.pos = pos
	self.size = size

	if not self.endfade then
		self:CreateModel()
	else
		self:CreateModel2()
	end
	
end

function Fade:SetRotation(rot)
	self.rotation = rot
end

function Fade:SetPosition(pos)
	self.pos = pos
end

function Fade:SetAlphaPercent(percent)
	
	if self.model then
		local c = self.model:GetColor()
		self.model:SetColor(Color(c.r, c.g, c.b, 255 * percent))
	end
	
end

function Fade:CreateModel()

	local vertexes = {}

	local width = self.size.x
	local height = self.size.y / 255
	
	for i = 1, 255 do
	
		local h1 = height*(i-1)
		if i == 255 then
			h1 = height*255
		end
		
		local color = math.lerp(Color.White, self.c, 1 - math.max(0, (i - 150)) / 105)
	
		table.insert(vertexes, Vertex(Vector2(0,h1), 
			Color(color.r,color.g,color.b,i)))
			
		table.insert(vertexes, Vertex(Vector2(width,height*i), 
			Color(color.r,color.g,color.b,i)))

	end
	
	self.model = Model.Create(vertexes)
	self.model:SetTopology(Topology.TriangleStrip)
	self.model:Set2D(true)
	
end

function Fade:CreateModel2()

	local vertexes = {}

	local width = self.size.x / 255
	local height = self.size.y / 255
	
	for i = 1, 255 do
	
		for j = 1, 255 do
			
			local h1 = height*(i-1)
			if i == 255 then
				--h1 = height*255
			end
			local w1 = width*(j-1)
			if j == 255 then
				w1 = width*255
			end
			local alpha = i
			if w1 <= self.size.x * self.endfade then
				local percent = w1 / (self.size.x * self.endfade)
				alpha = alpha * percent
			elseif w1 >= self.size.x * (1-self.endfade) then
				local minus = (1-self.endfade) * self.size.x
				local percent = (w1 - minus) / (self.size.x - minus)
				alpha = alpha * (1-percent)
			end
			
			local c = self.c
			
			table.insert(vertexes, Vertex(Vector2(w1,h1), 
				Color(c.r,c.g,c.b,alpha)))
				
			table.insert(vertexes, Vertex(Vector2(w1+width,height*i), 
				Color(c.r,c.g,c.b,alpha)))
				
		end

	end
	
	self.model = Model.Create(vertexes)
	self.model:SetTopology(Topology.TriangleStrip)
	self.model:Set2D(true)

end

function Fade:Render(args)

	if self.model then
		
		local t = Transform2()
		t:Translate(self.pos)
		if self.rotation then
			t:Translate(self.size / 2)
			t:Rotate(self.rotation)
			t:Translate(-self.size / 2)
		end
		
		Render:SetTransform(t)
		self.model:Draw()
		Render:ResetTransform()

	end
	
end
