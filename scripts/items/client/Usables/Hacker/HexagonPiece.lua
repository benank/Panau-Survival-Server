class 'HexagonPiece'

function HexagonPiece:__init(pos, size, ends)

	self.pos = pos
	self.size = size or 0.075
	self.rot = 0
	self.target_rot = 0
	self.scale = 0
	self.enabled = true
	self.move = 0
	self.delay = 0
	self.done = false
	self.ends = ends or {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false
		}
		
	self.has_ends = self:HasAnyEnds()
	self.connected = {}
	
	self:InitConnections()
		
	--[[
		 
	  5 /\  6
	  /   \
	 4|    | 1
	  |    |
	 3\   / 2
	   \ /
	--]]
	
end

function HexagonPiece:SetDone(done)

	self.done = done
	
end

function HexagonPiece:GetNumEnds()

	local cnt = 0
	for index, active in pairs(self.ends) do
		if active then cnt = cnt + 1 end
	end
	return cnt

end

function HexagonPiece:Initialize()

    local rotation = math.random(1,5)
	self.target_rot = math.pi * 2 / 6 * rotation
	self.rot = self.target_rot
	self.has_ends = self:HasAnyEnds()
    self:InitConnections()
    --self:PrintEnds()

    for i = 1, rotation do
        self:RotateConnections(1)
    end

end

function HexagonPiece:PrintEnds()
    local str = ""
    for index, active in pairs(self.ends) do
        str = str .. string.format("End %d is %s", index, tostring(active)) 
    end
    _debug(str)
end

function HexagonPiece:SetEnds(ends)

	self.ends = ends
    self:Initialize()
	
end

function HexagonPiece:InitConnections()

	for index, active in pairs(self.ends) do
		self.connected[index] = active
    end
    
    --self:RotateConnections(-1)

    --for k,v in pairs(self.connected) do print(k,v) end
    
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function HexagonPiece:RotateConnections(dir)

    local new_table = {}
    for index, connected in pairs(self.connected) do
    
        local new_index = index + dir
        if new_index > 6 then new_index = 1 end
        if new_index < 1 then new_index = 6 end
        new_table[new_index] = connected
        
    end
    
	self.connected = deepcopy(new_table)
    
end

function HexagonPiece:HasAnyEnds()

	local contains = false
	for index, active in pairs(self.ends) do
		if active then return true end
    end
    
end

function HexagonPiece:Contains(point)

	local contains = true
	if point.y < self.pos.y - self.line_size or point.y > self.pos.y + self.line_size then contains = false end
	local percent = Vector2.Distance(point, self.pos) / self.line_size
	if percent > 1 then contains = false end
	return contains
	
end

function HexagonPiece:SetEnabled(enabled)
	self.enabled = enabled
end

function HexagonPiece:Render(args)

	if not self.enabled then return end
	
	local white = Color.White
	
	if self.done then
		self.delay = self.delay + args.delta
		white = Color(12,232,0,255)
		if self.delay > 1.5 then
			self.move = self.move + args.delta * Render.Size.x * 0.8
			if self.delay > 2.5 then
				self.enabled = false
			end
		end
	end

	self.rot = self.rot + (self.target_rot - self.rot) * args.delta * 10

	local pos = self.pos or Render.Size / 2
	local line_size = Render.Size.x * self.size
	self.line_size = line_size
	
	local hexagon_color = Color(76,132,230,120)
	if not self.has_ends then
		hexagon_color = Color(67,137,200,120)
	end
	
	
	for i = 1, 6 do
		
		local t = Transform2()
		t:Translate(pos)
		t:Translate(Vector2(0,self.move))
		t:Rotate(math.pi * 2 / 6 * i + math.pi / 6 + math.pi)
		t:Rotate(self.rot)
		t:Scale(1)
		t:Translate(Vector2(0, line_size))
		Render:SetTransform(t)
		
		-- Hexagon fill
		Render:FillTriangle(
			Vector2(line_size / 1.725, 0),
			Vector2(-line_size / 1.725, 0),
			Vector2(0, -line_size),
			hexagon_color)
		-- Hexagon outside lines
		Render:DrawLine(Vector2(line_size / 1.725, 0), Vector2(-line_size / 1.725, 0), Color(255,255,255,255))
		
		-- Hexagon Inside Circle
		if self.has_ends then
			Render:FillCircle(Vector2(0, -line_size), line_size * 0.05, white)
		end
		
		if self.ends[i] then
			
			--Render:DrawLine(Vector2(0, -line_size), Vector2(), Color.White)
			
			-- Hexagon Lines Outward
			local line_width = line_size * 0.025
			Render:FillArea(
				Vector2(-line_width / 2, -line_size), 
				Vector2(line_width, line_size), 
				white)
				
			-- Hexagon Squares on the Lines
			local square_width = line_size * 0.1
			Render:FillArea(
				Vector2(-square_width / 2, -square_width - square_width * 2), 
				Vector2(square_width, square_width - square_width * 2), 
				white)
			
        end
        
		--Render:DrawText(Vector2(0, -line_size * 0.15), tostring(i), Color.Red, 25)
			
		
		Render:ResetTransform()
		
	end

end

function HexagonPiece:Rotate(dir)

	if self.has_ends and not self.done then
        self.target_rot = (self.target_rot + math.pi * 2 / 6 * dir)
        
        self:RotateConnections(dir)
        
		ClientSound.Play(AssetLocation.Game, {
			bank_id = 18,
			sound_id = 11,
			position = Camera:GetPosition(),
			angle = Angle()
		})

	end

end

--HexagonPiece = HexagonPiece()