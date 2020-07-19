class("Duplicate" , Actions)

function Actions.Duplicate:__init()
	MapEditor.Action.__init(self)
	
	self.objectsToDuplicateFrom = {}
	self.objectsDuplicated = {}
	
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		table.insert(self.objectsToDuplicateFrom , object)
	end)
	
	if #self.objectsToDuplicateFrom == 0 then
		self:Cancel()
		return
	end
	
	-- Duplicate the source objects. Unselect the source objects and select the new objects.
	for index , objectSource in ipairs(self.objectsToDuplicateFrom) do
		local position = objectSource:GetPosition()
		
		local newObject = Objects[objectSource.type](position , objectSource:GetAngle())
		objectSource:IterateProperties(function(property)
			newObject:SetProperty(property.name , property.value)
		end)
		
		MapEditor.map:AddObject(newObject)
		table.insert(self.objectsDuplicated , newObject)
		
		objectSource:SetSelected(false)
		newObject:SetSelected(true)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
	
	self:Confirm()
end

function Actions.Duplicate:Undo()
	-- Destroy the duplicated objects and unselect them.
	for index , object in ipairs(self.objectsDuplicated) do
		object:Destroy()
		MapEditor.map:RemoveObject(object)
		object:SetSelected(false)
	end
	
	-- Reselect the source objects.
	for index , objectSource in ipairs(self.objectsToDuplicateFrom) do
		objectSource:SetSelected(true)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Duplicate:Redo()
	-- Recreate the duplicated objects and select them.
	for index , object in ipairs(self.objectsDuplicated) do
		object:Recreate()
		MapEditor.map:AddObject(object)
		object:SetSelected(true)
	end
	
	-- Unselect the source objects.
	for index , objectSource in ipairs(self.objectsToDuplicateFrom) do
		objectSource:SetSelected(false)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end
