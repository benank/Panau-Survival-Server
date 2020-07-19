class("PropertiesMenu" , MapEditor)

-- Y is relative to height.
MapEditor.PropertiesMenu.position = Vector2(5 , 0.24)
MapEditor.PropertiesMenu.size = Vector2(350 , 300)
MapEditor.PropertiesMenu.yellow = Color(255 , 218 , 96)
MapEditor.PropertiesMenu.zebra1 = Color(0 , 0 , 0 , 64)
MapEditor.PropertiesMenu.zebra2 = Color(120 , 120 , 120 , 64)
MapEditor.PropertiesMenu.booleanTrue = Color(94 , 212 , 92)
MapEditor.PropertiesMenu.booleanFalse = Color(240 , 70 , 70)
MapEditor.PropertiesMenu.descriptionBoxMinHeight = 38

function MapEditor.PropertiesMenu:__init(propertyManagers) ; EGUSM.SubscribeUtility.__init(self)
	self.Destroy = MapEditor.PropertiesMenu.Destroy
	
	-- Copy propertyManagers into self.propertyManagers
	self.propertyManagers = {}
	for key , propertyManager in pairs(propertyManagers) do
		table.insert(self.propertyManagers , propertyManager)
	end
	
	-- Key: property name (string)
	-- Value: PropertyProprietor
	self.propertyProprietors = {}
	
	-- These controls are enabled/disabled on SetEnabled, and are also removed when they're removed
	-- from a table property.
	self.controls = {}
	
	-- These are the BaseWindows that contain the property controls, used to present the description
	-- when they're hovered over.
	self.propertyRows = {}
	-- Contains base, titleLabel, and textLabel.
	self.description = {}
	
	self.isMouseInWindow = false
	
	--
	-- Create window
	--
	
	local window = Window.Create()
	window:SetTitle("Properties menu")
	window:SetSize(MapEditor.PropertiesMenu.size)
	window:SetClosable(false)
	window:Subscribe("Resize" , function() MapEditor.PropertiesMenu.size = self.window:GetSize() end)
	window:Subscribe(
		"Render" ,
		function()
			local position = self.window:GetPosition()
			position.y = position.y / Render.Height
			MapEditor.PropertiesMenu.position = position
		end
	)
	self.window = window
	
	local scrollControl = ScrollControl.Create(self.window)
	scrollControl:SetDock(GwenPosition.Fill)
	scrollControl:SetScrollable(false , true)
	self.scrollControl = scrollControl
	
	local base = Rectangle.Create(self.window)
	base:SetMargin(Vector2(0 , 3) , Vector2(0 , 0))
	base:SetPadding(Vector2(3 , 3) , Vector2(3 , 3))
	base:SetColor(Color(128 , 128 , 128 , 64))
	base:SetDock(GwenPosition.Bottom)
	base:SetHeight(MapEditor.PropertiesMenu.descriptionBoxMinHeight)
	self.description.base = base
	
	local base = BaseWindow.Create(base)
	base:SetDock(GwenPosition.Fill)
	base:SetVisible(false)
	self.description.subBase = base
	
	local label = Label.Create(self.description.subBase)
	label:SetDock(GwenPosition.Top)
	label:SetHeight(18)
	label:SetTextColor(Color(208 , 208 , 208))
	self.description.titleLabel = label
	
	local label = Label.Create(self.description.subBase)
	label:SetDock(GwenPosition.Fill)
	label:SetTextColor(Color(250 , 240 , 172))
	label:SetWrap(true)
	self.description.textLabel = label
	
	self.textSize = 12
	
	self:ResolutionChange({size = Render.Size})
	
	--
	-- Create object controls
	--
	
	self.objects = {}
	self.objectTypeToObjects = {}
	-- Populate the two tables above from our property managers.
	for index , propertyManager in ipairs(self.propertyManagers) do
		if propertyManager.GetId then
			table.insert(self.objects , propertyManager)
			local objectArray = self.objectTypeToObjects[propertyManager.type]
			if objectArray == nil then
				self.objectTypeToObjects[propertyManager.type] = {propertyManager}
			else
				table.insert(objectArray , propertyManager)
			end
		end
	end
	-- If we are showing the properties of objects (instead of...the only thing it could be right now
	-- is the Map), show some object-specific things.
	if #self.objects ~= 0 then
		local base = BaseWindow.Create(self.scrollControl)
		base:SetPadding(Vector2(2 , 4) , Vector2(2 , 4))
		base:SetDock(GwenPosition.Top)
		local countAndParentBase = base
		
		-- "X objects selected" label
		local label = Label.Create()
		label:SetMargin(Vector2(0 , 0) , Vector2(16 , 0))
		if #self.objects == 1 then
			label:SetText(string.format("%i object selected" , #self.objects))
		else
			label:SetText(string.format("%i objects selected" , #self.objects))
		end
		label:SizeToContents()
		countAndParentBase:SetHeight(label:GetHeight() + 8)
		label:SetParent(countAndParentBase)
		label:SetDock(GwenPosition.Left)
		
		-- Get the common parent of all selected objects.
		local commonParent = nil
		for index , object in ipairs(self.objects) do
			if commonParent then
				if MapEditor.Object.Compare(commonParent , object:GetParent()) == false then
					commonParent = nil
					break
				end
			else
				commonParent = object:GetParent()
			end
		end
		
		-- "Parent" label
		local label = Label.Create(countAndParentBase)
		label:SetDock(GwenPosition.Left)
		label:SetText("Parent: ")
		label:SizeToContents()
		if commonParent == nil then
			label:SetTextColor(MapEditor.PropertiesMenu.yellow)
		end
		
		-- Parent label ("Light (id 13)")
		local label = Label.Create(countAndParentBase)
		label:SetDock(GwenPosition.Fill)
		if commonParent and commonParent ~= MapEditor.NoObject then
			label:SetText(string.format("%s (id %i)" , commonParent.type , commonParent:GetId()))
		else
			label:SetText("(none)")
		end
		
		-- If any of our objects have a static CreatePropertyMenuAuxControls function, call it on
		-- them, so they can have their own buttons or whatever.
		for objectType , objectArray in pairs(self.objectTypeToObjects) do
			local func = Objects[objectType].CreatePropertyMenuAuxControls
			if func then
				local base = BaseWindow.Create(self.scrollControl)
				base:SetMargin(Vector2(2 , 4) , Vector2(2 , 4))
				base:SetDock(GwenPosition.Top)
				base:SetHeight(20)
				
				local label = Label.Create(base)
				label:SetDock(GwenPosition.Left)
				label:SetAlignment(GwenPosition.CenterV)
				label:SetText(objectType..":  ")
				label:SizeToContents()
				
				func(base)
			end
		end
		
		-- Spacer
		local base = BaseWindow.Create(self.scrollControl)
		base:SetDock(GwenPosition.Top)
		base:SetHeight(12)
	end
	
	--
	-- Create property controls
	--
	
	-- Gather a list of common property names.
	-- Key: Property name (string)
	-- Value: array of Propertys
	local propertyMap = {}
	local propertyNameCount = 0
	-- Used for sorting property controls by their original order, since the order is otherwise lost
	-- along the way.
	local propertyNameToIndex = {}
	for index , propertyManager in ipairs(self.propertyManagers) do
		propertyManager:IterateProperties(function(property)
			local existingArray = propertyMap[property.name]
			if existingArray then
				table.insert(existingArray , property)
			else
				propertyMap[property.name] = {property}
				propertyNameCount = propertyNameCount + 1
				propertyNameToIndex[property.name] = propertyNameCount
			end
		end)
	end
	
	local namesToRemove = {}
	-- Filter out Propertys that are not common or have different types or subtypes.
	for propertyName , propertyArray in pairs(propertyMap) do
		local type = propertyArray[1].type
		local subtype = propertyArray[1].subtype
		
		if #propertyArray == #self.propertyManagers then
			for index , property in ipairs(propertyArray) do
				if property.type ~= type or property.subtype ~= subtype then
					table.insert(namesToRemove , propertyName)
					break
				end
			end
		else
			table.insert(namesToRemove , propertyName)
		end
	end
	for index , propertyName in ipairs(namesToRemove) do
		propertyMap[propertyName] = nil
	end
	
	-- Populate self.propertyProprietors.
	for propertyName , propertyArray in pairs(propertyMap) do
		local propertyProprietor = MapEditor.PropertyProprietor(propertyArray)
		self.propertyProprietors[propertyNameToIndex[propertyName]] = propertyProprietor
	end
	table.sort(
		self.propertyProprietors ,
		function(a , b)
			return propertyNameToIndex[a.name] < propertyNameToIndex[b.name]
		end
	)
	
	-- Get self.nameColumnWidth.
	self.nameColumnWidth = 0
	for index , propertyProprietor in ipairs(self.propertyProprietors) do
		local textWidth = Render:GetTextWidth(
			Utility.PrettifyVariableName(propertyProprietor.name) ,
			self.textSize
		)
		if textWidth > self.nameColumnWidth then
			self.nameColumnWidth = textWidth
		end
	end
	self.nameColumnWidth = self.nameColumnWidth + 6
	
	-- Create the property controls.
	for index , propertyProprietor in ipairs(self.propertyProprietors) do
		self:CreatePropertyControl(propertyProprietor , index)
	end
	
	--
	-- Event subs
	--
	
	self:EventSubscribe("PostTick")
	self:EventSubscribe("ResolutionChange")
	self:EventSubscribe("SetMenusEnabled")
end

function MapEditor.PropertiesMenu:CreatePropertyControl(propertyProprietor , index)
	local base = Rectangle.Create(self.scrollControl)
	base:SetPadding(Vector2(2 , 2) , Vector2(2 , 2))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(0)
	base:SetDataObject("propertyProprietor" , propertyProprietor)
	table.insert(self.propertyRows , base)
	
	if index % 2 == 0 then
		base:SetColor(MapEditor.PropertiesMenu.zebra1)
	else
		base:SetColor(MapEditor.PropertiesMenu.zebra2)
	end
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(self.textSize)
	label:SetText(Utility.PrettifyVariableName(propertyProprietor.name))
	label:SizeToContents()
	label:SetMargin(Vector2(0 , 0) , Vector2(self.nameColumnWidth - label:GetWidth() , 0))
	
	-- Make the label a yellow color if not all PropertyManagers have a common value.
	if propertyProprietor.hasCommonValue == false then
		label:SetTextColor(MapEditor.PropertiesMenu.yellow)
	end
	
	self:CreateEditControl(propertyProprietor , base)
	
	return base
end

function MapEditor.PropertiesMenu:CreateEditControl(propertyProprietor , parent , tableIndex)
	local propertyType
	if tableIndex then
		propertyType = propertyProprietor.subtype
	else
		propertyType = propertyProprietor.type
	end
	
	if propertyType == "number" then
		parent:SetHeight(parent:GetHeight() + self.textSize + 10)
		
		local control = TextBoxNumeric.Create(parent)
		control:SetDock(GwenPosition.Fill)
		control:SetDataObject("propertyProprietor" , propertyProprietor)
		if tableIndex then
			control:SetText(tostring(propertyProprietor.value[tableIndex]))
			control:SetDataNumber("tableIndex" , tableIndex)
			control:Subscribe("Blur" , self , self.TableNumberChanged)
		else
			control:SetText(tostring(propertyProprietor.value))
			control:Subscribe("Blur" , self , self.NumberChanged)
		end
		
		table.insert(self.controls , control)
		
		return control
	elseif propertyType == "string" then
		parent:SetHeight(parent:GetHeight() + self.textSize + 10)
		
		local textBox = TextBox.Create(parent)
		textBox:SetDock(GwenPosition.Fill)
		textBox:SetTextSize(self.textSize)
		textBox:SetDataObject("propertyProprietor" , propertyProprietor)
		if tableIndex then
			textBox:SetText(propertyProprietor.value[tableIndex])
			textBox:SetDataNumber("tableIndex" , tableIndex)
			textBox:Subscribe("Blur" , self , self.TableStringChanged)
		else
			textBox:SetText(propertyProprietor.value)
			textBox:Subscribe("Blur" , self , self.StringChanged)
		end
		
		table.insert(self.controls , textBox)
		
		return textBox
	elseif propertyType == "boolean" then
		parent:SetHeight(parent:GetHeight() + self.textSize + 8)
		
		local button = Button.Create(parent)
		button:SetDock(GwenPosition.Left)
		button:SetWidth(72)
		button:SetTextSize(self.textSize)
		button:SetText("")
		button:SetToggleable(true)
		button:SetTextNormalColor(MapEditor.PropertiesMenu.booleanFalse)
		button:SetTextPressedColor(MapEditor.PropertiesMenu.booleanTrue)
		button:SetTextHoveredColor(MapEditor.PropertiesMenu.booleanFalse)
		button:SetDataObject("propertyProprietor" , propertyProprietor)
		if tableIndex then
			button:SetToggleState(propertyProprietor.value[tableIndex])
			button:SetText(tostring(propertyProprietor.value[tableIndex]))
			button:SetDataNumber("tableIndex" , tableIndex)
			button:Subscribe("Toggle" , self , self.TableBooleanChanged)
		else
			button:SetToggleState(propertyProprietor.value)
			button:SetText(tostring(propertyProprietor.value))
			button:Subscribe("Toggle" , self , self.BooleanChanged)
		end
		
		table.insert(self.controls , button)
		
		return button
	elseif propertyType == "table" then
		if tableIndex then
			error("Property value cannot contain nested tables ("..propertyProprietor.name..")")
		end
		
		local base = BaseWindow.Create(parent)
		base:SetMargin(Vector2(0 , 0) , Vector2(0 , 4))
		base:SetDock(GwenPosition.Top)
		base:SetHeight(self.textSize + 8)
		local header = base
		
		local button = Button.Create(header)
		button:SetDock(GwenPosition.Left)
		button:SetTextSize(self.textSize)
		button:SetText("+")
		button:SetWidth(26)
		button:SetDataObject("propertyProprietor" , propertyProprietor)
		button:Subscribe("Press" , self , self.TableAddElement)
		table.insert(self.controls , button)
		local buttonAdd = button
		
		local label = Label.Create(header)
		label:SetMargin(Vector2(4 , 0) , Vector2(0 , 0))
		label:SetDock(GwenPosition.Fill)
		label:SetAlignment(GwenPosition.CenterV)
		label:SetTextSize(self.textSize)
		label:SetText(string.format("%i elements" , #propertyProprietor.value))
		
		local buttonData = {
			propertyProprietor = propertyProprietor ,
			label = label ,
			base = parent ,
			propertyControls = {} ,
			-- TODO: Is this even necessary? Why not just increment an index value?
			editControls = {} ,
		}
		
		buttonAdd:SetDataObject("buttonData" , buttonData)
		
		local height = header:GetHeight() + 4
		
		for index , value in ipairs(propertyProprietor.value) do
			local base = self:AddTableElement(buttonData)
			
			height = height + base:GetHeight() + 2
		end
		
		parent:SetHeight(parent:GetHeight() + height)
		
		return header
	elseif MapEditor.IsObjectType(propertyType) then
		parent:SetHeight(parent:GetHeight() + self.textSize + 10)
		
		local button = Button.Create(parent)
		button:SetDock(GwenPosition.Fill)
		button:SetTextSize(self.textSize)
		button:SetDataObject("propertyProprietor" , propertyProprietor)
		if tableIndex then
			if propertyProprietor.value[tableIndex] ~= MapEditor.NoObject then
				local object = propertyProprietor.value[tableIndex]
				button:SetText(string.format("Object: %s (id: %i)" , propertyType , object:GetId()))
			else
				button:SetText("Object: (None)")
			end
			
			button:SetDataNumber("tableIndex" , tableIndex)
			button:Subscribe("Press" , self , self.TableObjectChoose)
		else
			if propertyProprietor.value ~= MapEditor.NoObject then
				local object = propertyProprietor.value
				button:SetText(string.format("Object: %s (id: %i)" , propertyType , object:GetId()))
			else
				button:SetText("Object: (None)")
			end
			
			button:Subscribe("Press" , self , self.ObjectChoose)
		end
		
		table.insert(self.controls , button)
		
		return button
	elseif propertyType == "Color" then
		parent:SetHeight(parent:GetHeight() + self.textSize + 8)
		
		local rectangle = Rectangle.Create(parent)
		rectangle:SetDock(GwenPosition.Fill)
		
		-- This is an invisible button that is the size of the colored rectangle.
		local button = LabelClickable.Create(rectangle)
		button:SetDock(GwenPosition.Fill)
		button:SetDataObject("propertyProprietor" , propertyProprietor)
		table.insert(self.controls , button)
		
		if tableIndex then
			rectangle:SetColor(propertyProprietor.value[tableIndex])
			
			button:SetDataNumber("tableIndex" , tableIndex)
			button:Subscribe("Press" , self , self.TableColorChoose)
		else
			rectangle:SetColor(propertyProprietor.value)
			
			button:Subscribe("Press" , self , self.ColorChoose)
		end
		
		return rectangle
	elseif propertyType == "model" then
		local textBox = TextBox.Create(parent)
		textBox:SetDock(GwenPosition.Fill)
		textBox:SetTextSize(self.textSize)
		textBox:SetDataObject("propertyProprietor" , propertyProprietor)
		local modelTextBox = textBox
		
		table.insert(self.controls , textBox)
		
		local button = Button.Create(parent)
		button:SetPadding(Vector2(4 , 0) , Vector2(4 , 0))
		button:SetMargin(Vector2(2 , 0) , Vector2(2 , 0))
		button:SetDock(GwenPosition.Right)
		button:SetText("Model viewer")
		button:SizeToContents()
		button:SetDataObject("modelTextBox" , modelTextBox)
		table.insert(self.controls , button)
		local chooseButton = button
		
		if tableIndex then
			chooseButton:SetDataNumber("tableIndex" , tableIndex)
			chooseButton:Subscribe("Press" , self , self.TableModelViewerButton)
			
			modelTextBox:SetText(propertyProprietor.value[tableIndex])
			modelTextBox:SetDataNumber("tableIndex" , tableIndex)
			-- Cool, I can just reuse the (Table)StringChanged function.
			modelTextBox:Subscribe("Blur" , self , self.TableStringChanged)
		else
			chooseButton:Subscribe("Press" , self , self.ModelViewerButton)
			
			modelTextBox:SetText(propertyProprietor.value)
			modelTextBox:Subscribe("Blur" , self , self.StringChanged)
		end
		modelTextBox:MoveCaretToEnd()
		
		chooseButton:SetDataObject("propertyProprietor" , propertyProprietor)
		chooseButton:SetDataObject("label" , modelLabel)
		
		parent:SetHeight(parent:GetHeight() + button:GetHeight() + 10)
	else
		-- Fall back to just an "(unsupported)" label.
		local label = Label.Create(parent)
		label:SetDock(GwenPosition.Fill)
		label:SetAlignment(GwenPosition.CenterV)
		label:SetTextSize(self.textSize)
		label:SetText("(unsupported) "..tostring(propertyType))
		label:SetTextColor(Color.Red)
		label:SizeToContents()
		
		parent:SetHeight(parent:GetHeight() + label:GetHeight() + 6)
		
		return label
	end
end

function MapEditor.PropertiesMenu:AddTableElement(buttonData)
	local propertyProprietor = buttonData.propertyProprietor
	
	local base = BaseWindow.Create(buttonData.base)
	base:SetMargin(Vector2(0 , 1) , Vector2(0 , 1))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(0)
	table.insert(buttonData.propertyControls , base)
	
	-- Remove button
	local button = Button.Create(base)
	button:SetMargin(Vector2(0 , 0) , Vector2(8 , 2))
	button:SetDock(GwenPosition.Left)
	button:SetTextSize(self.textSize)
	button:SetTextNormalColor(Color(220 , 50 , 50))
	button:SetTextPressedColor(Color(150 , 40 , 40))
	button:SetTextHoveredColor(Color(255 , 70 , 70))
	button:SetText("x")
	button:SetWidth(26)
	button:SetDataObject("propertyProprietor" , propertyProprietor)
	button:SetDataObject("buttonData" , buttonData)
	button:Subscribe("Press" , self , self.TableRemoveElement)
	table.insert(self.controls , button)
	
	local index = #buttonData.editControls + 1
	local editControl = self:CreateEditControl(propertyProprietor , base , index)
	table.insert(buttonData.editControls , editControl)
	
	base:SetHeight(base:GetHeight() - 2)
	
	return base
end

function MapEditor.PropertiesMenu:SetVisible(visible)
	self.window:SetVisible(visible)
end

function MapEditor.PropertiesMenu:Destroy()
	self.window:Remove()
	
	self:UnsubscribeAll()
end

-- GWEN events

function MapEditor.PropertiesMenu:NumberChanged(control)
	local propertyProprietor = control:GetDataObject("propertyProprietor")
	propertyProprietor:SetValue(control:GetValue())
end

function MapEditor.PropertiesMenu:TableNumberChanged(control)
	local propertyProprietor = control:GetDataObject("propertyProprietor")
	local tableIndex = control:GetDataNumber("tableIndex")
	propertyProprietor:SetTableValue(tableIndex , control:GetValue())
end

function MapEditor.PropertiesMenu:StringChanged(textBox)
	local propertyProprietor = textBox:GetDataObject("propertyProprietor")
	propertyProprietor:SetValue(textBox:GetText())
end

function MapEditor.PropertiesMenu:TableStringChanged(textBox)
	local propertyProprietor = textBox:GetDataObject("propertyProprietor")
	local tableIndex = textBox:GetDataNumber("tableIndex")
	propertyProprietor:SetTableValue(tableIndex , textBox:GetText())
end

function MapEditor.PropertiesMenu:BooleanChanged(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	propertyProprietor:SetValue(button:GetToggleState())
	button:SetText(tostring(button:GetToggleState()))
end

function MapEditor.PropertiesMenu:TableBooleanChanged(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local tableIndex = button:GetDataNumber("tableIndex")
	propertyProprietor:SetTableValue(tableIndex , button:GetToggleState())
	button:SetText(tostring(button:GetToggleState()))
end

function MapEditor.PropertiesMenu:TableRemoveElement(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local buttonData = button:GetDataObject("buttonData")
	
	-- This index calculation is kind of janky: it iterates through the GWEN hierarchy.
	local index = -2
	local parent = button:GetParent()
	for n , control in ipairs(buttonData.base:GetChildren()) do
		index = index + 1
		if control == parent then
			break
		end
	end
	
	propertyProprietor:RemoveTableValue(index)
	
	buttonData.label:SetText(string.format("%i elements" , #propertyProprietor.value))
	
	local editControl = buttonData.editControls[index]
	table.remove(self.controls , table.find(self.controls , editControl))
	table.remove(self.controls , table.find(self.controls , button))
	table.remove(buttonData.editControls , index)
	
	local propertyControl = buttonData.propertyControls[index]
	propertyControl:Hide()
	propertyControl:Remove()
	table.remove(buttonData.propertyControls , index)
	
	buttonData.base:SetHeight(0)
	buttonData.base:SizeToChildren(false , true)
end

function MapEditor.PropertiesMenu:TableAddElement(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local buttonData = button:GetDataObject("buttonData")
	
	propertyProprietor:AddTableValue()
	
	buttonData.label:SetText(string.format("%i elements" , #propertyProprietor.value))
	
	self:AddTableElement(buttonData)
	
	buttonData.base:SetHeight(0)
	buttonData.base:SizeToChildren(false , true)
end

function MapEditor.PropertiesMenu:ObjectChoose(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local args = {
		special = "Object" ,
		propertyProprietor = propertyProprietor ,
		button = button ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

function MapEditor.PropertiesMenu:TableObjectChoose(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local tableIndex = button:GetDataNumber("tableIndex")
	local args = {
		special = "Object" ,
		propertyProprietor = propertyProprietor ,
		index = tableIndex ,
		tableActionType = "Set" ,
		button = button ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

function MapEditor.PropertiesMenu:ColorChoose(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local args = {
		special = "Color" ,
		propertyProprietor = propertyProprietor ,
		rectangle = button:GetParent() ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

function MapEditor.PropertiesMenu:TableColorChoose(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local tableIndex = button:GetDataNumber("tableIndex")
	local args = {
		special = "Color" ,
		propertyProprietor = propertyProprietor ,
		index = tableIndex ,
		tableActionType = "Set" ,
		rectangle = button:GetParent() ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

function MapEditor.PropertiesMenu:ModelViewerButton(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local modelTextBox = button:GetDataObject("modelTextBox")
	local args = {
		special = "model" ,
		propertyProprietor = propertyProprietor ,
		modelTextBox = modelTextBox ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

function MapEditor.PropertiesMenu:TableModelViewerButton(button)
	local propertyProprietor = button:GetDataObject("propertyProprietor")
	local tableIndex = button:GetDataNumber("tableIndex")
	local modelTextBox = button:GetDataObject("modelTextBox")
	local args = {
		special = "model" ,
		propertyProprietor = propertyProprietor ,
		index = tableIndex ,
		tableActionType = "Set" ,
		modelTextBox = modelTextBox ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
end

-- Events

function MapEditor.PropertiesMenu:PostTick()
	-- If the mouse is outside the window, focus the window, which blurs textboxes and such.
	-- Otherwise, GWEN likes to eat inputs which is extremely annoying.
	local relativeMousePos = self.window:AbsoluteToRelative(Mouse:GetPosition())
	local isInWindow = (
		relativeMousePos.x >= 0 and
		relativeMousePos.x <= self.window:GetWidth() and
		relativeMousePos.y >= 0 and
		relativeMousePos.y <= self.window:GetHeight()
	)
	if self.isMouseInWindow ~= isInWindow then
		if isInWindow == false then
			self.window:Focus()
		end
		self.isMouseInWindow = isInWindow
	end
	-- Set the description text depending what control we are hovering over.
	for index , base in ipairs(self.propertyRows) do
		local relativePos = base:AbsoluteToRelative(Mouse:GetPosition())
		if
			relativePos.x >= 0 and
			relativePos.x <= base:GetWidth() and
			relativePos.y >= 0 and
			relativePos.y <= base:GetHeight()
		then
			local propertyProprietor = base:GetDataObject("propertyProprietor")
			
			local title = Utility.PrettifyVariableName(propertyProprietor.name)
			self.description.titleLabel:SetText(title)
			
			self.description.textLabel:SetText(propertyProprietor.description)
			self.description.textLabel:SizeToContents()
			
			local baseHeight = math.max(
				self.description.base:GetHeight() ,
				self.description.textLabel:GetHeight() + 26
			)
			self.description.base:SetHeight(baseHeight)
			self.description.subBase:SetVisible(true)
			
			return
		end
	end
	
	self.description.subBase:SetVisible(false)
end

function MapEditor.PropertiesMenu:ResolutionChange(args)
	local position = MapEditor.PropertiesMenu.position
	self.window:SetPosition(Vector2(position.x , position.y * args.size.y))
end

function MapEditor.PropertiesMenu:SetMenusEnabled(enabled)
	for index , control in ipairs(self.controls) do
		control:SetEnabled(enabled)
	end
end
