class 'HexagonPuzzle'

function HexagonPuzzle:__init()


	--BANK 35 IS GOOD FOR SFX
	self.active = true
	self.space = 1.025 -- Space between hexagons
	self.size = 0.075
	self.time = 15999
	self.complete = false
	self.hexagons = {}
	
	self:InitHexagons()

	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("LocalPlayerInput", self, self.LPI)
	Events:Subscribe("MouseUp", self, self.MouseUp)

end

function HexagonPuzzle:InitHexagons()

	for i = 1, 7 do
	
		local pos = Render.Size / 2
		
		if i < 3 then
			pos = pos - Vector2(Render.Size.x * self.size * (i - 1) * 2 * self.space, Render.Size.x * self.size * self.space * 1.725) + Vector2(Render.Size.x * self.size * self.space, 0)
		elseif i < 6 then
			pos = pos - Vector2(Render.Size.x * self.size * (i - 4) * 2 * self.space, 0)
		else
			pos = pos - Vector2(Render.Size.x * self.size * (i - 7) * 2 * self.space, -Render.Size.x * self.size * self.space * 1.725) - Vector2(Render.Size.x * self.size * self.space, 0)
		end
			
		self.hexagons[i] = HexagonPiece(pos, self.size)
		
	end
	
	self:GenerateEndsForAll()

end

function HexagonPuzzle:GenerateEndsForAll()

	EG:GenerateEnds(self.difficulty, self.hexagons)
	self:CheckConnected()

end

function HexagonPuzzle:LPI()
	if self.active then return false end
end

function HexagonPuzzle:MouseUp(args)

	if (args.button == 1 or args.button == 2) and self.active then
	
		local mouse_pos = Mouse:GetPosition()
		
		for index, hexagon in pairs(self.hexagons) do
			if hexagon:Contains(mouse_pos) then
				hexagon:Rotate(args.button == 1 and 1 or -1)
			end
		end
		
	end
	
	self:CheckConnected()
	
end

function HexagonPuzzle:CheckConnected()

	local total_connections_made = 0
	local total_connections_needed = 0
    
    local f = string.format
	for index, hexagon in pairs(self.hexagons) do
        
        print(f("Hexagon %d: num ends: %d", index, hexagon:GetNumEnds()))
		total_connections_needed = total_connections_needed + hexagon:GetNumEnds()
		
		for _, pair_index in pairs(EG:GetConnections(index)) do
            
            print(f("Connection %d: Needs hexagon %d for connection", _, pair_index))
			for _, pair_index2 in pairs(EG:GetConnections(pair_index)) do
            
                print(f("Checking connection for pair %d (index %d)", pair_index2, _))
				if pair_index2 == index then
                    
                    print(f("Connection on index %d pair_index %d", index, pair_index))
					total_connections_made = total_connections_made + 1
						
				end
					
			end
			
		end
			
	end
	
	if total_connections_made == total_connections_needed and not self.complete then
	
		--Chat:Print("PUZZLE DONE WOO", Color.Yellow)
		for index, hexagon in pairs(self.hexagons) do
			hexagon:SetDone(true)
		end
		self.complete = true
		local sound = ClientSound.Create(AssetLocation.Game, {
			bank_id = 19,
			sound_id = 15,
			position = LocalPlayer:GetPosition(),
			angle = Angle()
			})

		sound:SetParameter(0,1)
		
	end
		
end
	

function HexagonPuzzle:Render(args)

	if self.active then
	
		if not self.complete then
			self.time = self.time - args.delta
			if self.time < 0 then
				self.time = 0
				self.active = false
				local sound = ClientSound.Create(AssetLocation.Game, {
					bank_id = 19,
					sound_id = 16,
					position = LocalPlayer:GetPosition(),
					angle = Angle()
				})

				sound:SetParameter(0,1)

			end
		end
		
		local text = string.format("%.1f", self.time)
		local text_size = Render.Size.x * 0.035
		local text_width = Render:GetTextWidth(text, text_size)
		local text_pos = Vector2(Render.Size.x / 2 - text_width / 2, Render.Size.y * 0.035)
		Render:DrawText(text_pos + Vector2(text_width * 0.015, text_width * 0.015), text, Color.Black, text_size)
		Render:DrawText(text_pos, text, Color.Red, text_size)
		
		if not Mouse:GetVisible() then
			Mouse:SetVisible(true)
		end

		for index, piece in pairs(self.hexagons) do
		
			piece:Render(args)
			if not piece.enabled then
				self.active = false
			end
			
		end
		
	elseif Mouse:GetVisible() then
	
		Mouse:SetVisible(false)
		
	end
		

end

function chat(args)

	if args.text == "/puzzle" then
		
		HexagonPuzzle()
		
	end
	
end
Events:Subscribe("LocalPlayerChat", chat)