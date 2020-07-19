class("Select" , Actions)

function Actions.Select:__init() ; Actions.SelectBase.__init(self , "Select")
	self.color = Color.LimeGreen
	self.objects = {}
end

function Actions.Select:OnObjectsChosen(objectIdToObject)
	if Controls.Get("Add to selection").state == 0 then
		MapEditor.map:IterateObjects(function(object)
			-- Make sure this object isn't what we selected.
			if objectIdToObject[object:GetId()] then
				return
			end
			
			if object:GetIsSelected() then
				table.insert(self.objects , object)
			end
		end)
	end
	
	for objectId , object in pairs(objectIdToObject) do
		if object:GetIsSelected() == false then
			-- There's a good chance that self.objects will already contain this object, which means it
			-- will be unselected and then selected again. This greatly simplifies the code, trust me.
			table.insert(self.objects , object)
		end
	end
	
	if #self.objects > 0 then
		self:Redo()
		self:Confirm()
	else
		self:Cancel()
	end
end

function Actions.Select:OnNothingChosen()
	if Controls.Get("Add to selection").state ~= 0 then
		self:Cancel()
		return
	end
	
	MapEditor.map:IterateObjects(function(object)
		if object:GetIsSelected() then
			table.insert(self.objects , object)
		end
	end)
	
	if #self.objects > 0 then
		self:Confirm()
		self:Redo()
	else
		self:Cancel()
	end
end

function Actions.Select:Undo()
	for index , object in ipairs(self.objects) do
		object:SetSelected(not object:GetIsSelected())
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.Select:Redo()
	for index , object in ipairs(self.objects) do
		object:SetSelected(not object:GetIsSelected())
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end
