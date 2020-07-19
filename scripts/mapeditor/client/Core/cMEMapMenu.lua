class("MapMenu" , MapEditor)

function MapEditor.MapMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	-- self.Destroy = MapEditor.MapMenu.Destroy
	
	MapEditor.mapMenu = self
	
	self:CreateWindow()
	
	self:EventSubscribe("ResolutionChange")
	self:EventSubscribe("SetMenusEnabled")
end

function MapEditor.MapMenu:CreateWindow()
	local window = Window.Create()
	window:SetTitle("Map menu")
	window:SetSize(Vector2(508 , 58))
	window:SetClosable(false)
	self.window = window
	
	self:ResolutionChange({size = Render.Size})
	
	-- States:
	--    "No map"
	--    "Unsaved map"
	--    "Saved map"
	self.state = "No map"
	
	self.buttons = {}
	
	local buttonNames = {
		"Preferences" ,
		"New" ,
		"Save" ,
		"Save as" ,
		"Load" ,
		"Properties" ,
		"Validate" ,
		"Test" ,
	}
	for index , buttonName in ipairs(buttonNames) do
		local button = Button.Create(self.window)
		button:SetPadding(Vector2(8 , 5) , Vector2(8 , 5))
		button:SetMargin(Vector2(1 , 0) , Vector2(1 , 0))
		button:SetDock(GwenPosition.Left)
		button:SetText(buttonName)
		button:SizeToContents()
		button:SetDataString("name" , buttonName)
		button:Subscribe("Press" , self , self.ButtonPressed)
		self.buttons[buttonName] = button
	end
	
	self:SetEnabled(true)
end

function MapEditor.MapMenu:SetEnabled(enabled)
	for index , button in pairs(self.buttons) do
		button:SetEnabled(enabled)
	end
	
	if self.state == "Unsaved map" then
		self.buttons["Save"]:SetEnabled(false)
	elseif self.state == "No map" then
		self.buttons["Save"]:SetEnabled(false)
		self.buttons["Save as"]:SetEnabled(false)
		self.buttons["Properties"]:SetEnabled(false)
		self.buttons["Validate"]:SetEnabled(false)
		self.buttons["Test"]:SetEnabled(false)
	end
end

function MapEditor.MapMenu:SetVisible(visible)
	self.window:SetVisible(visible)
end

-- GWEN events

function MapEditor.MapMenu:ButtonPressed(button)
	local name = button:GetDataString("name")
	
	if name == "Preferences" then
		MapEditor.preferencesMenu:SetVisible(not MapEditor.preferencesMenu:GetVisible())
	end
	
	if MapEditor.map then
		if name == "New" then
			MapEditor.map:SetAction(Actions.NewMap)
		elseif name == "Save" then
			MapEditor.map:Save()
		elseif name == "Save as" then
			MapEditor.map:SetAction(Actions.SaveAs)
		elseif name == "Load" then
			MapEditor.map:SetAction(Actions.Load)
		elseif name == "Properties" then
			MapEditor.map:OpenMapProperties()
		elseif name == "Validate" then
			MapEditor.map:Validate()
		elseif name == "Test" then
			MapEditor.map:Test()
		end
	else
		if name == "New" then
			Actions.NewMap()
		elseif name == "Load" then
			Actions.Load()
		end
	end
end

-- Events

function MapEditor.MapMenu:ResolutionChange(args)
	self.window:SetPosition(Vector2((args.size.x - self.window:GetWidth()) * 0.5 , 5))
end

function MapEditor.MapMenu:SetMenusEnabled(enabled)
	self:SetEnabled(enabled)
end
