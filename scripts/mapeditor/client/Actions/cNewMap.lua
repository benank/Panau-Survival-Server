class("NewMap" , Actions)

function Actions.NewMap:__init() ; MapEditor.Action.__init(self)
	self.Destroy = Actions.NewMap.Destroy
	
	self:CreateWindow()
	
	Mouse:SetVisible(true)
end

function Actions.NewMap:CreateWindow()
	local window = Window.Create()
	window:SetTitle("New map")
	window:SetSize(Vector2(160 , 120))
	-- window:SetClosable(false)
	window:MakeModal(true)
	window:Subscribe("WindowClosed" , self , self.WindowClosed)
	self.window = window
	
	self.window:SetPosition((Render.Size - self.window:GetSize()) / 2)
	
	local label = Label.Create(self.window)
	label:SetMargin(Vector2(0 , 2) , Vector2(0 , 4))
	label:SetDock(GwenPosition.Top)
	label:SetAlignment(GwenPosition.CenterH)
	label:SetText("Select a map type")
	label:SizeToContents()
	
	local mapTypes = {}
	for mapType , unused in pairs(MapTypes) do
		table.insert(mapTypes , mapType)
	end
	table.sort(mapTypes)
	for index , mapType in ipairs(mapTypes) do
		local button = Button.Create(self.window)
		button:SetPadding(Vector2(8 , 5) , Vector2(8 , 5))
		button:SetMargin(Vector2(0 , 1) , Vector2(0 , 1))
		button:SetDock(GwenPosition.Top)
		button:SetText(mapType)
		button:SizeToContents()
		button:SetDataString("mapType" , mapType)
		button:Subscribe("Press" , self , self.ButtonPressed)
	end
end

function Actions.NewMap:Destroy()
	if MapEditor.map then
		self:Cancel()
	end
	
	Mouse:SetVisible(false)
	
	self.window:Remove()
end

-- GWEN events

function Actions.NewMap:WindowClosed()
	self:Destroy()
end

function Actions.NewMap:ButtonPressed(button)
	local mapType = button:GetDataString("mapType")
	
	if MapEditor.map then
		MapEditor.map:Destroy()
	end
	
	MapEditor.Map(Vector3(-6550 , 215 , -3290) , mapType)
	
	self:Destroy()
end
