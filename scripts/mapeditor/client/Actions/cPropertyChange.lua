-- Helps with adding undo/redo to property changes and also handles advanced things like choosing
-- an Object or Color.

class("PropertyChange" , Actions)

function Actions.PropertyChange:__init(args)
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	self.propertyProprietor = args.propertyProprietor
	self.properties = self.propertyProprietor.properties
	self.value = args.value
	self.index = args.index
	self.tableActionType = args.tableActionType
	if self.index then
		self.type = self.properties[1].subtype
	else
		self.type = self.properties[1].type
	end
	self.special = args.special
	
	self.previousValues = {}
	
	if self.special == "Object" then
		Events:Fire("SetMenusEnabled" , false)
		self.objectChooseButton = args.button
		self.oldButtonText = self.objectChooseButton:GetText()
		
		MapEditor.ObjectChooser(self.type , self.ObjectChosen , self)
	elseif self.special == "Color" then
		Events:Fire("SetMenusEnabled" , false)
		self.rectangle = args.rectangle
		
		MapEditor.ColorChooser(self.rectangle , self.ColorChosen , self)
	elseif self.special == "model" then
		Events:Fire("SetMenusEnabled" , false)
		
		self.modelTextBox = args.modelTextBox
		
		MapEditor.ModelChooser(self.ModelChosen , self)
		if self.propertyProprietor.value and self.propertyProprietor.value:len() > 1 then
			MapEditor.modelViewer:SetModelPath(self.propertyProprietor.value)
			MapEditor.modelViewer:SpawnStaticObject()
		end
	else
		self:Apply()
		self:Confirm()
	end
end

function Actions.PropertyChange:Apply()
	for index , property in ipairs(self.properties) do
		local propertyChangeArgs = {
			name = property.name ,
			newValue = self.value ,
		}
		
		if property.type == "table" then
			if self.tableActionType == "Set" then
				self.previousValues[index] = self:Copy(property.value[self.index])
				property.value[self.index] = self.value
			elseif self.tableActionType == "Remove" then
				self.previousValues[index] = self:Copy(property.value[self.index])
				table.remove(property.value , self.index)
			elseif self.tableActionType == "Add" then
				table.insert(property.value , property.defaultElement)
			end
		else
			self.previousValues[index] = self:Copy(property.value)
			property.value = self.value
		end
		
		propertyChangeArgs.oldValue = self.previousValues[index]
		
		property.propertyManager:PropertyChanged(propertyChangeArgs)
	end
end

function Actions.PropertyChange:Undo()
	for index , property in ipairs(self.properties) do
		local propertyChangeArgs = {
			name = property.name ,
			newValue = self.previousValues[index] ,
			oldValue = self.value ,
		}
		
		if property.type == "table" then
			if self.tableActionType == "Set" then
				property.value[self.index] = self:Copy(self.previousValues[index])
			elseif self.tableActionType == "Remove" then
				table.insert(property.value , self.index , self:Copy(self.previousValues[index]))
			elseif self.tableActionType == "Add" then
				table.remove(property.value , #property.value)
			end
		else
			property.value = self:Copy(self.previousValues[index])
		end
		
		property.propertyManager:PropertyChanged(propertyChangeArgs)
	end
	
	if self.special == "Object" then
		self.objectChooseButton:SetText(self.oldButtonText)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

function Actions.PropertyChange:Redo()
	self:Apply()
	
	if self.special == "Object" then
		self.objectChooseButton:SetText(self.newButtonText)
	end
	
	MapEditor.map:UpdatePropertiesMenu()
end

-- Calls Copy unless our type is an Object.
function Actions.PropertyChange:Copy(value)
	if self.propertyProprietor.isObject then
		return value
	else
		return Copy(value) or value
	end
end

function Actions.PropertyChange:ObjectChosen(object)
	local Cancel = function()
		self:UnsubscribeAll()
		self:Cancel()
		
		Events:Fire("SetMenusEnabled" , true)
	end
	
	-- Make sure we chose an object.
	if object then
		-- Make sure it's different to the previous object.
		local changed
		if self.index then
			changed = self.propertyProprietor:SetTableValue(self.index , object , true)
		else
			changed = self.propertyProprietor:SetValue(object , true)
		end
		if changed == false then
			Cancel()
			return
		end
		
		-- Disallow self-selecting by making sure it's not one of the currently selected objects.
		if object ~= MapEditor.NoObject then
			local isSelf = false
			MapEditor.map.selectedObjects:IterateObjects(function(selectedObject)
				if object:GetId() == selectedObject:GetId() then
					isSelf = true
					return
				end
			end)
			if isSelf then
				Chat:Print("Cannot select the same object!" , Color.DarkRed)
				self:Cancel()
				return
			end
		end
		
		self.value = object
		self:Apply()
		
		self:UnsubscribeAll()
		self:Confirm()
		
		if object ~= MapEditor.NoObject then
			self.newButtonText = string.format("Object: %s (id: %i)" , self.type , object:GetId())
		else
			self.newButtonText = string.format("Object: (None)")
		end
		self.objectChooseButton:SetText(self.newButtonText)
		
		Events:Fire("SetMenusEnabled" , true)
	else
		Cancel()
	end
end

function Actions.PropertyChange:ColorChosen(color)
	local Cancel = function()
		self:UnsubscribeAll()
		self:Cancel()
		
		Events:Fire("SetMenusEnabled" , true)
	end
	
	if color then
		-- Make sure it's different to the previous color.
		local changed
		if self.index then
			changed = self.propertyProprietor:SetTableValue(self.index , color , true)
		else
			changed = self.propertyProprietor:SetValue(color , true)
		end
		if changed == false then
			Cancel()
			return
		end
		
		self.value = color
		self:Apply()
		
		self:UnsubscribeAll()
		self:Confirm()
		
		Events:Fire("SetMenusEnabled" , true)
	else
		self.rectangle:SetColor(self.propertyProprietor.value)
		Cancel()
	end
end

function Actions.PropertyChange:ModelChosen(modelPath)
	local Cancel = function()
		self:UnsubscribeAll()
		self:Cancel()
		Events:Fire("SetMenusEnabled" , true)
	end
	
	if modelPath == nil then
		Cancel()
		return
	end
	
	local changed
	if self.index then
		changed = self.propertyProprietor:SetTableValue(self.index , modelPath , true)
	else
		changed = self.propertyProprietor:SetValue(modelPath , true)
	end
	if changed == false then
		Cancel()
		return
	end
	
	self.value = modelPath
	self:Apply()
	
	self.modelTextBox:SetText(modelPath)
	self.modelTextBox:MoveCaretToEnd()
	
	self:UnsubscribeAll()
	self:Confirm()
	Events:Fire("SetMenusEnabled" , true)
end
