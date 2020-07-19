class("ApplyArray" , Actions)

function Actions.ApplyArray:__init() ; MapEditor.Action.__init(self)
	-- Create the ObjectDeletionHelper using all of the Array objects that are selected and their
	-- children.
	
	local objects = {}
	local arrayObjects = {}
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		if object.type == "Array" then
			table.insert(objects , object)
			table.insert(arrayObjects , object)
			
			object:IterateChildrenRecursive(function(child)
				table.insert(objects , child)	
			end)
		end
	end)
	self.objectDeletionHelper = MapEditor.ObjectDeletionHelper(objects)
	
	-- Create copies of the Array source objects and duplicates.
	
	self.newObjects = {}
	
	local ApplyDuplicateManager
	ApplyDuplicateManager = function(duplicateManager , parentObject , parentDuplicates)
		local sourceObject = duplicateManager.sourceObject
		-- Copy the source object.
		local copiedObject = sourceObject:CreateCopy()
		table.insert(self.newObjects , copiedObject)
		MapEditor.map:AddObject(copiedObject)
		if parentObject ~= MapEditor.NoObject then
			copiedObject:SetParent(parentObject)
		end
		copiedObject:SetPosition(sourceObject:GetPosition())
		copiedObject:SetAngle(sourceObject:GetAngle())
		-- Copy the duplicates of the source object.
		local copiedDuplicates = {}
		for index , sourceDuplicate in ipairs(duplicateManager.duplicates) do
			local copiedDuplicate = sourceDuplicate:CreateCopy()
			table.insert(self.newObjects , copiedDuplicate)
			table.insert(copiedDuplicates , copiedDuplicate)
			MapEditor.map:AddObject(copiedDuplicate)
			copiedDuplicate:SetLocalPosition(sourceDuplicate:GetLocalPosition())
			copiedDuplicate:SetLocalAngle(sourceDuplicate:GetLocalAngle())
			if parentDuplicates then
				copiedDuplicate:SetParent(parentDuplicates[index])
			elseif parentObject ~= MapEditor.NoObject then
				copiedDuplicate:SetParent(parentObject , true)
			end
		end
		-- Recursion for our duplicate managers' children.
		for key , duplicateManager in pairs(duplicateManager.duplicateManagers) do
			local copiedChild = ApplyDuplicateManager(
				duplicateManager ,
				copiedObject ,
				copiedDuplicates
			)
		end
		
		return copiedObject
	end
	
	for index , arrayObject in ipairs(arrayObjects) do
		for key , duplicateManager in pairs(arrayObject.baseDuplicateManager.duplicateManagers) do
			local copiedChild = ApplyDuplicateManager(duplicateManager , arrayObject:GetParent())
		end
	end
	
	-- Apply the deletion helper and confirm the action.
	
	self.objectDeletionHelper:Apply()
	MapEditor.map:UpdatePropertiesMenu()
	
	self:Confirm()
end

function Actions.ApplyArray:Undo()
	self.objectDeletionHelper:Undo()
	
	for index , newObject in ipairs(self.newObjects) do
		newObject:Destroy()
		MapEditor.map:RemoveObject(newObject)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.ApplyArray:Redo()
	self.objectDeletionHelper:Apply()
	
	for index , newObject in ipairs(self.newObjects) do
		newObject:Recreate()
		MapEditor.map:AddObject(newObject)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end
