class("Map" , MapEditor)

function MapEditor.Map:__init(initialPosition , mapType)
	EGUSM.SubscribeUtility.__init(self)
	local memberNames = {
		"type" ,
		"version" ,
	}
	MapEditor.Marshallable.__init(self , memberNames)
	MapEditor.ObjectManager.__init(self)
	MapEditor.PropertyManager.__init(self)
	
	self.Destroy = MapEditor.Map.Destroy
	
	MapEditor.map = self
	
	if MapEditor.maplessState then
		MapEditor.maplessState:Destroy()
	end
	
	self.type = mapType
	self.objectIdCounter = 1
	-- This is used for the filename and is set when saving or loading.
	self.name = nil
	self.isEnabled = true
	self.version = MapEditor.version
	
	self.undoableActions = {}
	self.redoableActions = {}
	self.currentAction = nil
	self.isInGame = false
	
	self.selectedObjects = MapEditor.ObjectManager()
	
	MapEditor.mapMenu.state = "Unsaved map"
	
	self.spawnMenu = MapEditor.SpawnMenu()
	self.propertiesMenu = nil
	
	for index , propertyArgs in ipairs(MapTypes[self.type].properties) do
		self:AddProperty(propertyArgs)
	end
	
	self.controlDisplayers = {
		selection = MapEditor.ControlDisplayer{
			name = "Selection" ,
			linesFromBottom = 4 ,
			"Select" ,
			"Deselect" ,
			"Add to selection" ,
		} ,
		actions = MapEditor.ControlDisplayer{
			name = "Actions" ,
			linesFromBottom = 3 ,
			"Undo" ,
			"Redo" ,
			"Move object" ,
			"Rotate object" ,
			"Delete object" ,
			"Floor object" ,
			"Duplicate object" ,
			"Parent object" ,
		}
	}
	
	self:SetCameraType(MapEditor.Preferences.camType , initialPosition)
	
	self:EventSubscribe("Render")
	self:EventSubscribe("ControlDown")
end

function MapEditor.Map:SetEnabled(enabled)
	if self.isEnabled == enabled then
		return
	end
	
	self.isEnabled = enabled
	
	self:SetMenusVisible(self.isEnabled)
	
	for name , controlDisplayer in pairs(self.controlDisplayers) do
		controlDisplayer:SetVisible(self.isEnabled)
	end
	
	if self.propertiesMenu then
		self.propertiesMenu:Destroy()
		self.propertiesMenu = nil
	end
	
	Mouse:SetVisible(self.isEnabled)
	
	self.camera.isEnabled = self.isEnabled
	self.camera.isInputEnabled = false
	
	if self.isEnabled then
		self:IterateObjects(function(object)
			object:Recreate()
		end)
	else
		self:IterateObjects(function(object)
			object:Destroy()
		end)
	end
end

function MapEditor.Map:SetMenusVisible(visible)
	MapEditor.mapMenu:SetVisible(visible)
	self.spawnMenu:SetVisible(visible)
	if MapEditor.preferencesMenu:GetVisible() then
		MapEditor.preferencesMenu:SetVisible(visible)
	end
	if self.propertiesMenu ~= nil then
		self.propertiesMenu:SetVisible(visible)
	end
end

function MapEditor.Map:Destroy()
	self:UnsubscribeAll()
	
	self.camera:Destroy()
	
	self.spawnMenu:Destroy()
	
	for name , controlDisplayer in pairs(self.controlDisplayers) do
		controlDisplayer:Destroy()
	end
	
	if self.propertiesMenu then
		self.propertiesMenu:Destroy()
	end
	
	self:IterateObjects(function(object)
		object:Destroy()
	end)
	
	Mouse:SetVisible(false)
	
	MapEditor.map = nil
end

function MapEditor.Map:SetAction(actionClass , ...)
	if self.currentAction ~= nil then
		error("Already have an Action! ("..tostring(self.currentAction)..")")
		return
	end
	
	for name , controlDisplayer in pairs(self.controlDisplayers) do
		controlDisplayer:SetVisible(false)
	end
	
	local finished = false
	local cancelled = false
	
	-- This is all pretty silly because Actions can finish immediately. Bleh.
	self.ActionFinish = function() finished = true end
	self.ActionCancel = function() cancelled = true end
	
	self.currentAction = actionClass(...)
	
	self.ActionFinish = MapEditor.Map.ActionFinish
	self.ActionCancel = MapEditor.Map.ActionCancel
	
	if finished then
		table.insert(self.undoableActions , self.currentAction)
		self.redoableActions = {}
		self.currentAction = nil
	elseif cancelled then
		self.currentAction = nil
	else
		Events:Fire("SetMenusEnabled" , false)
	end
	
	if finished or cancelled then
		for name , controlDisplayer in pairs(self.controlDisplayers) do
			controlDisplayer:SetVisible(true)
		end
	end
end

function MapEditor.Map:ActionFinish()
	Events:Fire("SetMenusEnabled" , true)
	
	for name , controlDisplayer in pairs(self.controlDisplayers) do
		controlDisplayer:SetVisible(true)
	end
	
	table.insert(self.undoableActions , self.currentAction)
	self.redoableActions = {}
	
	self.currentAction = nil
end

function MapEditor.Map:ActionCancel()
	Events:Fire("SetMenusEnabled" , true)
	
	for name , controlDisplayer in pairs(self.controlDisplayers) do
		controlDisplayer:SetVisible(true)
	end
	
	self.currentAction = nil
end

function MapEditor.Map:Undo()
	local count = #self.undoableActions
	if count > 0 then
		local action = self.undoableActions[count]
		table.remove(self.undoableActions , count)
		action:Undo()
		table.insert(self.redoableActions , action)
	end
end

function MapEditor.Map:Redo()
	local count = #self.redoableActions
	if count > 0 then
		local action = self.redoableActions[count]
		table.remove(self.redoableActions , count)
		action:Redo()
		table.insert(self.undoableActions , action)
	end
end

function MapEditor.Map:UpdatePropertiesMenu()
	local objects = {}
	self.selectedObjects:IterateObjects(function(object)
		table.insert(objects , object)
	end)
	
	if #objects > 0 then
		if self.propertiesMenu then
			self.propertiesMenu:Destroy()
		end
		
		self.propertiesMenu = MapEditor.PropertiesMenu(objects)
	else
		if self.propertiesMenu then
			self.propertiesMenu:Destroy()
			self.propertiesMenu = nil
		end
	end
end

function MapEditor.Map:SetCameraType(cameraType , initialPosition , initialAngle)
	if self.camera then
		self.camera:Destroy()
		self.camera = nil
	end
	
	if cameraType == "Noclip" then
		self.camera = MapEditor.NoclipCamera(initialPosition , initialAngle)
	elseif cameraType == "Orbit" then
		self.camera = MapEditor.OrbitCamera(initialPosition , initialAngle)
	else
		error("Invalid camera type")
	end
end

function MapEditor.Map:OpenMapProperties()
	if self.propertiesMenu then
		self.propertiesMenu:Destroy()
		self.propertiesMenu = nil
	else
		self.propertiesMenu = MapEditor.PropertiesMenu{self}
	end
end

function MapEditor.Map:Save()
	local args = {
		name = self.name ,
		marshalledSource = self:Marshal() ,
	}
	Network:Send("SaveMap" , args)
	
	MapEditor.mapMenu.state = "Saved map"
end

function MapEditor.Map:Validate()
	-- TODO: It should focus on the source Object of the error.
	local successOrError = MapTypes[self.type].Validate(self)
	-- TODO: This should be a popup or something.
	if successOrError == true then
		Chat:Print("Validation successful" , Color(165 , 250 , 160))
		return true
	else
		Chat:Print("Validation failed: "..successOrError , Color(250 , 160 , 160))
		return false
	end
end

function MapEditor.Map:Test()
	local success = self:Validate()
	if success then
		local args = {
			mapType = self.type ,
			marshalledMap = self:Marshal() ,
		}
		Network:Send("TestMap" , args)
		
		self:SetEnabled(false)
		
		if MapTypes[self.type].Test then
			MapTypes[self.type].Test()
		end
	end
end

-- Static functions

MapEditor.Map.Load = function(marshalledSource)
	if MapEditor.version ~= marshalledSource.version then
		-- TODO: something that is not this
		Chat:Print("Map cannot be loaded because it has a different file version" , Color.DarkRed)
		return
	end
	
	local map = MapEditor.Map(Vector3(-6550 , 215 , -3290) , marshalledSource.type)
	
	-- Unmarshal Objects.
	for index , objectData in pairs(marshalledSource.objects) do
		-- Note: Adding 'object' variable to objectData for convenience.
		objectData.object = MapEditor.Object.Unmarshal(objectData)
		map:AddObject(objectData.object)
	end
	-- Set parents.
	for index , objectData in pairs(marshalledSource.objects) do
		if objectData.parent then
			local parent = map:GetObject(objectData.parent)
			objectData.object:SetParent(parent)
		end
	end
	-- Calculate highestId and averageObjectPosition.
	local highestId = 1
	local averageObjectPosition = Vector3(0 , 0 , 0)
	local objectCount = 0
	for index , objectData in pairs(marshalledSource.objects) do
		if objectData.id > highestId then
			highestId = objectData.id
		end
		
		averageObjectPosition = averageObjectPosition + objectData.object:GetPosition()
		objectCount = objectCount + 1
	end
	averageObjectPosition = averageObjectPosition / objectCount
	if objectCount > 0 then
		map.camera:SetPosition(averageObjectPosition)
		map.objectIdCounter = highestId + 1
	end
	-- Unmarshal Object properties. This is done here because some properties are Objects, so all
	-- Objects must be loaded first.
	for index , objectData in pairs(marshalledSource.objects) do
		MapEditor.PropertyManager.Unmarshal(objectData.object , objectData.properties)
	end
	-- Unmarshal map properties here, for the same reason as above.
	MapEditor.PropertyManager.Unmarshal(map , marshalledSource.properties)
	
	MapEditor.mapMenu.state = "Saved map"
	
	return map
end

-- Events

function MapEditor.Map:Render()
	if self.isEnabled == false then
		return
	end
	
	local isInGame = Game:GetState() == GUIState.Game
	if MapEditor.isInGame ~= isInGame then
		MapEditor.isInGame = isInGame
		self:SetMenusVisible(isInGame)
	end
	
	-- Draw map name.
	local mapName = self.name or "Untitled map"
	local position = Vector2(Render.Width - 6 , 34)
	position.x = position.x - Render:GetTextWidth(mapName)
	Render:DrawText(
		position ,
		mapName ,
		Color(196 , 196 , 196)
	)
	
	self:IterateObjects(function(object)
		if object.Render then
			object:Render()
		end
	end)
end

function MapEditor.Map:ControlDown(args)
	if self.isEnabled == false then
		return
	end
	
	if self.currentAction == nil then
		if args.name == "Undo" then
			self:Undo()
		elseif args.name == "Redo" then
			self:Redo()
		end
		
		if self.camera.isInputEnabled == false and self:IsEmpty() == false then
			if args.name == "Select" then
				self:SetAction(Actions.Select)
			elseif args.name == "Deselect" then
				self:SetAction(Actions.Deselect)
			elseif args.name == "Move object" then
				self:SetAction(Actions.Move)
			elseif args.name == "Rotate object" then
				self:SetAction(Actions.Rotate)
			elseif args.name == "Delete object" then
				self:SetAction(Actions.Delete)
			elseif args.name == "Floor object" then
				self:SetAction(Actions.Floor)
			elseif args.name == "Duplicate object" then
				self:SetAction(Actions.Duplicate)
			elseif args.name == "Parent object" then
				self:SetAction(Actions.Parent)
			end
		end
	end
end
