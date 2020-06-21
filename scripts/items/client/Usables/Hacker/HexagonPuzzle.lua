class 'HexagonPuzzle'

function HexagonPuzzle:__init(difficulty, time)

    self.delta = 0
    self.last_time = Client:GetElapsedSeconds()

    self.window = Button.Create()
    self.window:SetSize(Render.Size)
    self.window:SetBackgroundVisible(false)
    self.window:BringToFront()
    self.window:Subscribe("Press", self, self.PressHexagon)
    self.window:Subscribe("RightPress", self, self.RightPressHexagon)

    self.difficulty = difficulty
	self.active = true
	self.space = 1.025 -- Space between hexagons
	self.size = 0.075
	self.time = var(time)
	self.complete = false
	self.hexagons = {}
	
	self:InitHexagons()

    self.window:Subscribe("PostRender", self, self.Render)

    self.subs = 
    {
        Events:Subscribe("LocalPlayerInput", self, self.LPI),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }

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

	self.hexagons = EG:GenerateEnds(self.difficulty, self.hexagons)
	self:CheckConnected()

end

function HexagonPuzzle:LPI()
	if self.active then return false end
end

function HexagonPuzzle:RightPressHexagon()
    self:MouseUp({button = 2})
end

function HexagonPuzzle:PressHexagon()
    self:MouseUp({button = 1})
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
        
		total_connections_needed = total_connections_needed + hexagon:GetNumEnds()
		
		for _, pair_index in pairs(EG:GetConnections(index)) do
            
			for _, pair_index2 in pairs(EG:GetConnections(pair_index)) do
            
				if pair_index2 == index then
                    
					total_connections_made = total_connections_made + 1
						
				end
					
			end
			
		end
			
	end
	
	if total_connections_made == total_connections_needed and not self.complete then
	
		for index, hexagon in pairs(self.hexagons) do
			hexagon:SetDone(true)
		end
		self.complete = true
		ClientSound.Play(AssetLocation.Game, {
			bank_id = 19,
			sound_id = 15,
			position = Camera:GetPosition(),
			angle = Angle()
            })
            
        Mouse:SetVisible(false)

        Network:Send(var("items/HackComplete"):get())
		
	end
		
end
	

function HexagonPuzzle:Render(window)

    self.delta = Client:GetElapsedSeconds() - self.last_time
    self.last_time = Client:GetElapsedSeconds()

	if self.active then
	
        if not Mouse:GetVisible() and not self.complete then
            Mouse:SetVisible(true)
        end
        
        local time = tonumber(self.time:get())
        if not self.complete then
            local time_adj = time - self.delta
			self.time:set(time_adj)
			if time < 0 then
				self.time:set(0)
				self.active = false
				ClientSound.Play(AssetLocation.Game, {
					bank_id = 19,
					sound_id = 16,
					position = Camera:GetPosition(),
					angle = Angle()
                })
                
                Mouse:SetVisible(false)

			end
		end
		
		local text = string.format("%.1f", time)
		local text_size = Render.Size.x * 0.035
		local text_width = Render:GetTextWidth(text, text_size)
		local text_pos = Vector2(Render.Size.x / 2 - text_width / 2, Render.Size.y * 0.035)
		Render:DrawText(text_pos + Vector2(text_width * 0.015, text_width * 0.015), text, Color.Black, text_size)
		Render:DrawText(text_pos, text, Color.Red, text_size)
		
		for index, piece in pairs(self.hexagons) do
		
			piece:Render({delta = self.delta})
			if not piece.enabled then
				self.active = false
			end
			
        end
        
    else
        
        for k, event in pairs(self.subs) do
            Events:Unsubscribe(event)
        end

        self.window:Remove()

        if not self.complete then
            Network:Send(var("items/FailHack"):get())
        end
    end
		

end

Network:Subscribe(var("items/StartHack"):get(), function(args)
    HexagonPuzzle(args.difficulty, args.time or 10)
    Mouse:SetVisible(true)
end)
