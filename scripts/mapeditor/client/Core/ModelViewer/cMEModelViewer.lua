MapEditor.modelNames = {}

class("ModelViewer" , MapEditor)

function MapEditor.ModelViewer:__init()
	MapEditor.modelViewer = self
	
	self.staticObject = nil
	self.modelPath = nil
	self.isVisible = nil
	self.oldCameraPosition = nil
	self.oldCameraAngle = nil
	self.modelBounds = nil
	self.isUpdatingBounds = false
	self.scaleCameraOnModelChange = true
	self.isMouseInWindow = false
	
	self:CreateWindow()
	
	self:SetVisible(false)
	
	Events:Subscribe("PreTick" , self , self.PreTick)
	
	Network:Subscribe("ReceiveModelNames" , self , self.ReceiveModelNames)
	Network:Subscribe("ReceiveModelName" , self , self.ReceiveModelName)
	Network:Subscribe("ReceiveTaggedModelAdd" , self , self.ReceiveTaggedModelAdd)
	Network:Subscribe("ReceiveTaggedModelRemove" , self , self.ReceiveTaggedModelRemove)
	
	Network:Send("RequestModelNames" , ".")
end

function MapEditor.ModelViewer:CreateWindow()
	local slightlyLargeFontSize = 16
	local labelWidth = 60
	
	-- Window
	
	local size = Vector2(180 + Render.Width * 0.125 , 250 + Render.Height * 0.25)
	local position = Vector2(Render.Width - size.x - 5 , Render.Height / 2 - size.y / 2)
	local window = Window.Create()
	window:SetSize(size)
	window:SetPosition(position)
	window:SetTitle("Model viewer")
	window:Subscribe("WindowClosed" , self , self.WindowClosed)
	self.window = window
	
	-- scaleCameraOnModelChange checkbox
	
	local checkBoxHeight = 16
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(0 , 1) , Vector2(0 , 10))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(checkBoxHeight)
	
	local checkBox = CheckBox.Create(base)
	checkBox:SetDock(GwenPosition.Left)
	checkBox:SetSize(Vector2(checkBoxHeight , checkBoxHeight))
	checkBox:SetChecked(self.scaleCameraOnModelChange)
	checkBox:Subscribe("CheckChanged" , self , self.ScaleCameraCheckBoxChanged)
	
	local label = Label.Create(base)
	-- SetPosition is the goto statement of GUI coding.
	label:SetPosition(Vector2(checkBoxHeight + 4 , 3))
	label:SetText("Scale camera on model change")
	label:SizeToContents()
	
	-- Search textbox
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(0 , 0) , Vector2(2 , 6))
	base:SetDock(GwenPosition.Top)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(slightlyLargeFontSize)
	label:SetText("Search ")
	label:SizeToContents()
	label:SetWidth(labelWidth)
	
	local textBox = TextBox.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:SetText("")
	textBox:Subscribe("Blur" , self , self.SearchTextBoxChanged)
	self.searchTextBox = textBox
	
	base:SetHeight(slightlyLargeFontSize + 2)
	
	-- Tab control
	
	self.tabControl = TabControl.Create(self.window)
	self.tabControl:SetMargin(Vector2(0 , 0) , Vector2(0 , 4))
	self.tabControl:SetDock(GwenPosition.Fill)
	self.tabs = {
		allModels = ModelViewerTabs.AllModels(self) ,
		tags = ModelViewerTabs.Tags(self) ,
		searchResults = ModelViewerTabs.SearchResults(self) ,
		-- recentlyUsed = ModelViewerTabs.RecentlyUsed(self) ,
	}
	
	-- Tag textbox
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(0 , 2) , Vector2(2 , 2))
	base:SetDock(GwenPosition.Bottom)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(slightlyLargeFontSize)
	label:SetText("Tags: ")
	label:SizeToContents()
	label:SetWidth(labelWidth)
	
	local textBox = TextBox.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:SetText("")
	textBox:SetEnabled(false)
	textBox:Subscribe("Blur" , self , self.TagsTextBoxChanged)
	self.tagsTextBox = textBox
	
	base:SetHeight(slightlyLargeFontSize + 2)
	
	-- Name textbox
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(0 , 2) , Vector2(2 , 2))
	base:SetDock(GwenPosition.Bottom)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(slightlyLargeFontSize)
	label:SetText("Name: ")
	label:SizeToContents()
	label:SetWidth(labelWidth)
	
	local textBox = TextBox.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:SetText("")
	textBox:SetEnabled(false)
	textBox:Subscribe("Blur" , self , self.NameTextBoxChanged)
	self.nameTextBox = textBox
	
	base:SetHeight(slightlyLargeFontSize + 2)
	
	-- Model textbox
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(0 , 2) , Vector2(2 , 2))
	base:SetDock(GwenPosition.Bottom)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(slightlyLargeFontSize)
	label:SetText("Model: ")
	label:SizeToContents()
	label:SetWidth(labelWidth)
	
	local textBox = TextBox.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:Subscribe("Blur" , self , self.ModelTextBoxChanged)
	self.modelTextBox = textBox
	
	base:SetHeight(slightlyLargeFontSize + 2)
end

function MapEditor.ModelViewer:Destroy()
	self:SetVisible(false)
	self.window:Remove()
end

function MapEditor.ModelViewer:SetVisible(visible)
	if self.isVisible == visible then
		return
	end
	self.isVisible = visible
	
	self.window:SetVisible(visible)
	
	if self.isVisible == true then
		if MapEditor.map ~= nil then
			MapEditor.map.spawnMenu:SetVisible(false)
			
			self.oldCameraPosition = MapEditor.map.camera.position
			self.oldCameraAngle = MapEditor.map.camera.angle
			local newCameraPosition = Copy(self.oldCameraPosition)
			newCameraPosition.y = 2200
			MapEditor.map:SetCameraType("Orbit" , newCameraPosition)
			
			MapEditor.map.controlDisplayers.camera:SetVisible(true)
		end
	else
		if MapEditor.map ~= nil then
			MapEditor.map.spawnMenu:SetVisible(true)
			
			local cameraType = MapEditor.Preferences.camType
			MapEditor.map:SetCameraType(cameraType , self.oldCameraPosition , self.oldCameraAngle)
		end
		
		if self.staticObject ~= nil then
			self.staticObject:Remove()
			self.staticObject = nil
		end
	end
end

function MapEditor.ModelViewer:GetModelPath()
	return self.modelPath
end

function MapEditor.ModelViewer:SetModelPath(modelPath)
	self.modelPath = modelPath
	-- Get the model's tags and set the text of the tags textbox.
	if self.modelPath ~= nil then
		self.modelTextBox:SetText(self.modelPath)
		
		self.nameTextBox:SetEnabled(true)
		self.nameTextBox:SetText(MapEditor.modelNames[self.modelPath] or "")
		
		self.tagsTextBox:SetEnabled(true)
		local tags = MapEditor.modelToTags[self.modelPath]
		if tags ~= nil then
			local text = table.concat(tags , ", ")
			self.tagsTextBox:SetText(text)
		else
			self.tagsTextBox:SetText("")
		end
	else
		self.modelTextBox:SetText("")
		
		self.nameTextBox:SetEnabled(false)
		self.nameTextBox:SetText("")
		
		self.tagsTextBox:SetEnabled(false)
		self.tagsTextBox:SetText("")
	end
end

function MapEditor.ModelViewer:SpawnStaticObject()
	local model = self:GetModelPath()
	if model == nil then
		return
	end
	
	if self.staticObject ~= nil then
		self.staticObject:Remove()
	end
	
	self.staticObject = ClientStaticObject.Create{
		position = MapEditor.map.camera:GetPosition() ,
		angle = Angle(math.tau/2 , 0 , 0) ,
		model = model ,
	}
	self.modelBounds = nil
	self.isUpdatingBounds = true
end

function MapEditor.ModelViewer:UpdateStaticObjectBounds()
	if self.staticObject == nil then
		self.isUpdatingBounds = false
		return
	end
	
	if IsValid(self.staticObject) == false then
		return
	end
	
	local b1 , b2 = self.staticObject:GetBoundingBox()
	-- The bounds are sometimes zero if the object just spawned, probably only when it's loaded for
	-- the first time.
	local hasBounds = not(b1 == Vector3.Zero and b2 == Vector3.Zero)
	if hasBounds and b1:IsNaN() == false and b2:IsNaN() == false then
		local camPosition = MapEditor.map.camera:GetPosition()
		b1 = b1 - camPosition
		b2 = b2 - camPosition
		
		self.modelBounds = {b1 , b2}
		self.isUpdatingBounds = false
		
		local size = Vector3.Distance(b1 , b2)
		MapEditor.map.camera.targetPosition = camPosition + (b1 + b2) * 0.5
		if self.scaleCameraOnModelChange == true then
			MapEditor.map.camera.distance = 1.75 + size * 1.2
		end
	end
end

-- Events

function MapEditor.ModelViewer:PreTick()
	if self.isUpdatingBounds == true then
		self:UpdateStaticObjectBounds()
	end
	
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
end

-- Network events

function MapEditor.ModelViewer:ReceiveModelNames(modelNames)
	MapEditor.modelNames = modelNames
end

function MapEditor.ModelViewer:ReceiveModelName(args)
	MapEditor.modelNames[args.model] = args.name
	
	self.tabs.allModels:SetModelName(args)
	self.tabs.tags:SetModelName(args)
end

function MapEditor.ModelViewer:ReceiveTaggedModelAdd(args)
	-- Get the existingTags array.
	local existingTags = MapEditor.modelToTags[args.model]
	-- If it doesn't exist yet, create it.
	if existingTags == nil then
		existingTags = {}
		MapEditor.modelToTags[args.model] = existingTags
	end
	-- Add args.tag to MapEditor.modelToTags[args.model].
	table.insert(existingTags , args.tag)
	-- If this is the first model with this tag, add an entry to MapEditor.taggedModels.
	local models = MapEditor.taggedModels[args.tag]
	if models == nil then
		models = {}
		local newEntry = {args.tag , models}
		table.insert(MapEditor.taggedModels , newEntry)
		
		MapEditor.taggedModels[args.tag] = models
	end
	-- Add args.model to MapEditor.taggedModels[args.tag].
	table.insert(models , args.model)
	-- Add the model button to the tags tab.
	self.tabs.tags:AddModelButton{tag = args.tag , model = args.model}
	self.tabs.tags:UpdateTag(args.tag)
	self.tabs.tags:SortModelButtons(args.tag)
end

function MapEditor.ModelViewer:ReceiveTaggedModelRemove(args)
	-- Get the existingTags array.
	local existingTags = MapEditor.modelToTags[args.model]
	-- If it doesn't exist yet, create it.
	if existingTags == nil then
		existingTags = {}
		MapEditor.modelToTags[args.model] = existingTags
	end
	-- Remove args.tag from MapEditor.modelToTags[args.model].
	table.remove(existingTags , index)
	-- Remove args.model from MapEditor.taggedModels[args.tag].
	local models = MapEditor.taggedModels[args.tag]
	for index , model in ipairs(models) do
		if model == args.model then
			table.remove(models , index)
			break
		end
	end
	-- If no more models have this tag, remove the tag entry from MapEditor.taggedModels.
	if #models == 0 then
		MapEditor.taggedModels[args.tag] = nil
		for index , tagEntry in ipairs(MapEditor.taggedModels) do
			if tagEntry[1] == args.tag then
				table.remove(MapEditor.taggedModels , index)
				break
			end
		end
	end
	-- Remove the model button from the tags tab.
	self.tabs.tags:RemoveModelButton{
		tag = args.tag ,
		model = args.model ,
		removeTag = #models == 0 ,
	}
end

-- GWEN events

function MapEditor.ModelViewer:WindowClosed()
	self:SetVisible(false)
end

function MapEditor.ModelViewer:SearchTextBoxChanged()
	self.tabControl:SetCurrentTab(self.tabs.searchResults.tabButton)
	
	local text = self.searchTextBox:GetText()
	if text:len() > 0 then
		self.tabs.searchResults:Search(text)
	else
		self.tabs.searchResults:Clear()
	end
end

function MapEditor.ModelViewer:ScaleCameraCheckBoxChanged(checkBox)
	self.scaleCameraOnModelChange = checkBox:GetChecked()
end

function MapEditor.ModelViewer:ModelTextBoxChanged()
	local modelPath = self.modelTextBox:GetText()
	
	modelPath = modelPath:gsub(".blz/" , ".bl/")
	modelPath = modelPath:gsub(".nlz/" , ".nl/")
	modelPath = modelPath:gsub(".fl/" ,  ".nl/")
	modelPath = modelPath:gsub(".flz/" , ".nl/")
	
	local OnInvalidPath = function()
		self:SetModelPath(nil)
		self.modelTextBox:SetText("[Invalid]")
		
		if self.staticObject ~= nil then
			self.staticObject:Remove()
			self.staticObject = nil
		end
	end
	
	local result = modelPath:find("/+[^/]*$") -- Find the last '/' in modelPath.
	if result == nil then
		OnInvalidPath()
		return
	end
	local archive = modelPath:sub(1 , result - 1)
	local model = modelPath:sub(result + 1)
	
	local models = MapEditor.modelList[archive]
	if models == nil or table.find(models , model) == nil then
		OnInvalidPath()
		return
	end
	
	self:SetModelPath(modelPath)
	self:SpawnStaticObject()
end

function MapEditor.ModelViewer:NameTextBoxChanged()
	Network:Send("SetModelName" , {model = self.modelPath , name = self.nameTextBox:GetText()})
	
	self.window:Blur()
end

function MapEditor.ModelViewer:TagsTextBoxChanged()
	-- Get and clean the text.
	local text = self.tagsTextBox:GetText()
	text = text:gsub(", " , ",")
	text = text:gsub(" ," , ",")
	-- Get the newTags array.
	local newTags = text:split("," , true)
	if newTags[#newTags] == "" then
		table.remove(newTags)
	end
	-- Get the existingTags array.
	local existingTags = MapEditor.modelToTags[self.modelPath]
	-- If it doesn't exist yet, create it.
	if existingTags == nil then
		existingTags = {}
		MapEditor.modelToTags[self.modelPath] = existingTags
	end
	-- Find any tags in existingTags that aren't in newTags and remove them.
	for index = #existingTags , 1 , -1 do
		local tag = existingTags[index]
		if table.find(newTags , tag) == nil then
			Network:Send("TaggedModelRemove" , {tag = tag , model = self.modelPath})
		end
	end
	-- Find any tags in newTags that aren't in existingTags and add them.
	for index , tag in ipairs(newTags) do
		if table.find(existingTags , tag) == nil then
			Network:Send("TaggedModelAdd" , {tag = tag , model = self.modelPath})
		end
	end
	
	self.window:Blur()
end
