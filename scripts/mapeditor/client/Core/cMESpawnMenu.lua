class("SpawnMenu" , MapEditor)

function MapEditor.SpawnMenu:__init() ; EGUSM.SubscribeUtility.__init(self)
	self.Destroy = MapEditor.SpawnMenu.Destroy
	
	-- Get self.objectNames from the current map's type's objects list, and also all generic objects.
	self.objectNames = {}
	for index , objectName in ipairs(MapTypes[MapEditor.map.type].objects) do
		table.insert(self.objectNames , objectName)
	end
	table.sort(self.objectNames)
	if MapEditor.map.type ~= "Generic" then
		for index , objectName in ipairs(MapTypes.Generic.objects) do
			table.insert(self.objectNames , objectName)
		end
	end
	
	self:CreateWindow()
	
	self:EventSubscribe("ResolutionChange")
	self:EventSubscribe("SetMenusEnabled")
end

function MapEditor.SpawnMenu:CreateWindow()
	local window = Window.Create()
	window:SetTitle("Spawn menu")
	window:SetSize(Vector2(140 , 300))
	window:SetClosable(false)
	self.window = window
	
	self:ResolutionChange({size = Render.Size})
	
	self.spawnButtons = {}
	for index , objectName in ipairs(self.objectNames) do
		local button = Button.Create(self.window)
		button:SetPadding(Vector2(8 , 5) , Vector2(8 , 5))
		button:SetMargin(Vector2(0 , 1) , Vector2(0 , 1))
		button:SetDock(GwenPosition.Top)
		button:SetText(Utility.PrettifyVariableName(objectName))
		button:SizeToContents()
		button:SetDataString("objectName" , objectName)
		button:Subscribe("Press" , self , self.SpawnButtonPressed)
		table.insert(self.spawnButtons , button)
	end
end

function MapEditor.SpawnMenu:Destroy()
	self:UnsubscribeAll()
	self.window:Remove()
end

function MapEditor.SpawnMenu:SetEnabled(enabled)
	for index , spawnButton in ipairs(self.spawnButtons) do
		spawnButton:SetEnabled(enabled)
	end
end

function MapEditor.SpawnMenu:SetVisible(visible)
	self.window:SetVisible(visible)
end

-- GWEN events

function MapEditor.SpawnMenu:SpawnButtonPressed(button)
	local objectName = button:GetDataString("objectName")
	local objectClass = Objects[objectName]
	MapEditor.map:SetAction(Actions.ObjectPlacer , objectClass)
end

-- Events

function MapEditor.SpawnMenu:ResolutionChange(args)
	self.window:SetPosition(Vector2(args.size.x - self.window:GetWidth() - 5 , args.size.y * 0.25))
end

function MapEditor.SpawnMenu:SetMenusEnabled(enabled)
	self:SetEnabled(enabled)
end
