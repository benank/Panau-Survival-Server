class("Deselect" , Actions)

function Actions.Deselect:__init() ; Actions.SelectBase.__init(self , "Deselect")
	self.color = Color.DarkRed
	self.objects = {}
end

function Actions.Deselect:OnObjectsChosen(objectIdToObject)
	self.objects = {}
	-- Only add to self.objects those that are selected.
	for objectId , object in pairs(objectIdToObject) do
		if object:GetIsSelected() then
			table.insert(self.objects , object)
		end
	end
	
	self:Redo()
	
	self:Confirm()
end

function Actions.Deselect:OnNothingChosen()
	self:Cancel()
end

function Actions.Deselect:Undo()
	for index , object in ipairs(self.objects) do
		object:SetSelected(true)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Deselect:Redo()
	for index , object in ipairs(self.objects) do
		object:SetSelected(false)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end
