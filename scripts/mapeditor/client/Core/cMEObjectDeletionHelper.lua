class("ObjectDeletionHelper" , MapEditor)

function MapEditor.ObjectDeletionHelper:__init(objectsToDelete)
	self.objectsInfo = {}
	-- If we delete an Object that is referenced elsewhere, those properties get reset.
	-- Each element is like, {property = Property , originalValue = blar , index = optional}
	self.properties = {}
	
	for key , object in pairs(objectsToDelete) do
		-- oldChildren is a copy of the object's children.
		local oldChildren = {}
		object:IterateChildren(function(child)
			table.insert(oldChildren , child)
		end)
		local objectInfo = {
			object = object ,
			isSelected = object:GetIsSelected() ,
			oldParent = object:GetParent() ,
			oldChildren = oldChildren ,
		}
		table.insert(self.objectsInfo , objectInfo)
	end
	
	-- Populate self.properties.
	
	local TestProperty = function(property)
		local IsInObjects = function(propertyValue)
			if propertyValue ~= MapEditor.NoObject then
				local objectId = propertyValue:GetId()
				for index , objectInfo in ipairs(self.objectsInfo) do
					if objectInfo.object:GetId() == objectId then
						return true
					end
				end
			end
			
			return false
		end
		
		if MapEditor.IsObjectType(property.type) then
			if IsInObjects(property.value) then
				table.insert(self.properties , {property = property , originalValue = property.value})
			end
		elseif MapEditor.IsObjectType(property.subtype) then
			for index , object in ipairs(property.value) do
				if IsInObjects(object) then
					local propertyInfo = {
						property = property ,
						index = index ,
						originalValue = object ,
					}
					table.insert(self.properties , propertyInfo)
				end
			end
		end
	end
	
	MapEditor.map:IterateProperties(TestProperty)
	
	MapEditor.map:IterateObjects(function(object)
		object:IterateProperties(TestProperty)
	end)
end

function MapEditor.ObjectDeletionHelper:Apply()
	for index , objectInfo in ipairs(self.objectsInfo) do
		local object = objectInfo.object
		-- Remove the object from its parent's children.
		if object:GetParent() ~= MapEditor.NoObject then
			object:SetParent(MapEditor.NoObject , true)
		end
		-- Unparent the object's children.
		object:IterateChildren(function(child)
			child:SetParent(MapEditor.NoObject , true)
		end)
		-- Destroy the object.
		object:Destroy()
		-- Remove the object from the map.
		MapEditor.map.selectedObjects:RemoveObject(object)
		MapEditor.map:RemoveObject(object)
	end
	-- For each property in self.properties, set the value to MapEditor.NoObject.
	for index , propertyInfo in ipairs(self.properties) do
		propertyInfo.property:SetValue(MapEditor.NoObject , propertyInfo.index)
	end
end

function MapEditor.ObjectDeletionHelper:Undo()
	for index , objectInfo in ipairs(self.objectsInfo) do
		local object = objectInfo.object
		-- Recreate the object.
		object:Recreate()
		MapEditor.map:AddObject(object)
		-- Reselect it if it was selected before.
		if objectInfo.isSelected then
			MapEditor.map.selectedObjects:AddObject(object)
		end
		-- Reparent the object.
		object:SetParent(objectInfo.oldParent , true)
	end
	-- Children are reparented here instead of in the above loop because otherwise the children
	-- could get reparented while they are still destroyed. Array didn't like that, at least.
	for index , objectInfo in ipairs(self.objectsInfo) do
		for index , child in pairs(objectInfo.oldChildren) do
			child:SetParent(objectInfo.object , true)
		end
	end
	-- For each property in self.properties, reset the value.
	for index , propertyInfo in ipairs(self.properties) do
		propertyInfo.property:SetValue(propertyInfo.originalValue , propertyInfo.index)
	end
end
