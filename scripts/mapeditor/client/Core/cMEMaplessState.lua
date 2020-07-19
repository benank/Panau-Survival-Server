class("MaplessState" , MapEditor)

function MapEditor.MaplessState:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.Destroy = MapEditor.MaplessState.Destroy
	
	MapEditor.maplessState = self
	
	self.yawTimer = nil
	self.offsetYaw = math.random() * math.tau
	self.yawMult = 0.0075
	if math.random() > 0.5 then
		self.yawMult = self.yawMult * -1
	end
	
	if Game:GetState() ~= GUIState.Loading then
		self:GameLoad()
	end
	
	Game:FireEvent("gui.hud.hide")
	
	self:EventSubscribe("Render")
	self:EventSubscribe("CalcView")
	self:EventSubscribe("GameLoad")
end

function MapEditor.MaplessState:Destroy()
	self:UnsubscribeAll()
	
	Game:FireEvent("gui.hud.show")
	
	MapEditor.maplessState = nil
end

-- Events

function MapEditor.MaplessState:Render()
	Render:FillArea(Vector2.Zero , Render.Size , Color(30 , 30 , 30 , 188))
	
	local text = "github.com/dreadmullet/JC2-MP-MapEditor"
	local fontSize = 18
	local textSize = Render:GetTextSize(text , fontSize)
	local position = Vector2(
		Render.Width * 0.5 - textSize.x * 0.5 ,
		Render.Height - textSize.y * 2
	)
	Render:DrawText(
		position - Vector2.One ,
		text ,
		Color.Black ,
		fontSize
	)
	Render:DrawText(
		position ,
		text ,
		Color(160 , 160 , 160) ,
		fontSize
	)
	
	Mouse:SetVisible(true)
end

function MapEditor.MaplessState:CalcView()
	local yaw
	if self.yawTimer then
		yaw = self.yawTimer:GetSeconds() * self.yawMult + self.offsetYaw
	else
		yaw = self.offsetYaw
	end
	local pitch = math.rad(-6.6)
	local angle = Angle(yaw , pitch , 0)
	local origin = Vector3(-1600 , 245 , 1000)
	local direction = angle * Vector3.Backward
	local distance = 14700
	local position = origin + direction * distance
	
	Camera:SetAngle(angle)
	Camera:SetPosition(position)
	
	return false
end

function MapEditor.MaplessState:GameLoad()
	self.yawTimer = Timer()
end
