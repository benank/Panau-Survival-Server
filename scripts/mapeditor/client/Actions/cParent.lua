class("Parent" , Actions)

function Actions.Parent:__init() ; MapEditor.Action.__init(self)
	-- Each element is like, {object = Object , originalParent = Object}
	self.objectsInfo = {}
	self.parent = nil
	
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		table.insert(self.objectsInfo , {object = object , originalParent = object:GetParent()})
	end)
	
	MapEditor.ObjectChooser("Object" , self.ObjectChosen , self)
end

function Actions.Parent:Undo()
	for index , objectInfo in ipairs(self.objectsInfo) do
		objectInfo.object:SetParent(objectInfo.originalParent , true)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Parent:Redo()
	for index , objectInfo in ipairs(self.objectsInfo) do
		objectInfo.object:SetParent(self.parent , true)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Parent:ObjectChosen(objectChosen)
	if objectChosen == nil then
		self:Cancel()
		return
	end
	
	local changed = false
	for index , objectInfo in ipairs(self.objectsInfo) do
		if objectInfo.object:GetCanHaveParent(objectChosen) == false then
			self:Cancel()
			return
		end
		
		if MapEditor.Object.Compare(objectInfo.object:GetParent() , objectChosen) == false then
			changed = true
		end
	end
	
	if changed == false then
		self:Cancel()
		return
	end
	
	self.parent = objectChosen
	self:Redo()
	self:Confirm()
end
