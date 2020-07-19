MapEditor.taggedModels = {}
MapEditor.modelToTags = {}

class("Tags" , ModelViewerTabs)

function ModelViewerTabs.Tags:__init(modelViewer)
	self.modelViewer = modelViewer
	
	self.colors = {
		modelsArea =          Color(136 , 136 , 136 , 26) ,
		textNormal =          Color(216 , 216 , 216 , 255) ,
		textHovered =         Color(255 , 255 , 255 , 255) ,
		textSelected =        Color(240 , 234 , 160 , 255) ,
		textSelectedHovered = Color(255 , 246 , 96 , 255) ,
	}
	self.modelButtonHeight = 16
	
	self.page = self.modelViewer.tabControl:AddPage("Tags"):GetPage()
	self.activeTagButton = nil
	self.activeModelButton = nil
	
	local scrollControl = ScrollControl.Create(self.page)
	scrollControl:SetScrollable(false , true)
	scrollControl:SetDock(GwenPosition.Left)
	scrollControl:SetWidthAutoRel(0.36)
	self.tagsArea = scrollControl
	
	local base = Rectangle.Create(self.page)
	base:SetColor(self.colors.modelsArea)
	base:SetDock(GwenPosition.Fill)
	
	local scrollControl = ScrollControl.Create(base)
	scrollControl:SetScrollable(false , true)
	scrollControl:SetDock(GwenPosition.Fill)
	self.modelsArea = scrollControl
	
	self.tagToTagButton = {}
	self.tagToModelButtons = {}
	
	Network:Subscribe("ReceiveTaggedModels" , self , self.ReceiveTaggedModels)
	
	Network:Send("RequestTaggedModels" , ".")
end

function ModelViewerTabs.Tags:SetModelName(args)
	local tags = MapEditor.modelToTags[args.model]
	if tags == nil then
		return
	end
	
	for index , tag in ipairs(tags) do
		local modelButtons = self.tagToModelButtons[tag]
		if modelButtons ~= nil then
			local modelButton = modelButtons[args.model]
			if modelButton ~= nil then
				modelButton:SetText(args.name or args.model)
			end
			
			self:SortModelButtons(tag)
		end
	end
end

function ModelViewerTabs.Tags:AddTagButton(args)
	local button = LabelClickable.Create(self.tagsArea)
	button:SetAlignment(GwenPosition.CenterV)
	button:SetDock(GwenPosition.Top)
	button:SetText(string.format("(%d) %s" , #args.models , args.tag))
	button:SizeToContents()
	button:SetHeight(button:GetHeight() + 4)
	button:SetTextNormalColor(self.colors.textNormal)
	button:SetTextHoveredColor(self.colors.textHovered)
	button:SetDataString("tag" , args.tag)
	button:SetDataBool("hasLoadedModels" , false)
	button:Subscribe("Press" , self , self.TagSelected)
	self.tagToTagButton[args.tag] = button
	
	local base = BaseWindow.Create(self.modelsArea)
	base:SetDock(GwenPosition.Top)
	base:SetVisible(false)
	local modelsContainer = base
	
	button:SetDataObject("modelsContainer" , modelsContainer)
	
	self.tagToModelButtons[args.tag] = {}
end

function ModelViewerTabs.Tags:AddModelButton(args)
	local tagButton = self.tagToTagButton[args.tag]
	if tagButton == nil then
		self:AddTagButton{tag = args.tag , models = {args.model}}
		tagButton = self.tagToTagButton[args.tag]
		tagButton:SetDataBool("hasLoadedModels" , true)
		
		self:SortTagButtons()
	end
	
	local modelsContainer = tagButton:GetDataObject("modelsContainer")
	
	local button = LabelClickable.Create(modelsContainer)
	button:SetAlignment(GwenPosition.CenterV)
	button:SetDock(GwenPosition.Top)
	button:SetText(MapEditor.modelNames[args.model] or args.model)
	button:SetHeight(self.modelButtonHeight)
	button:SetTextNormalColor(self.colors.textNormal)
	button:SetTextHoveredColor(self.colors.textHovered)
	button:SetDataString("model" , args.model)
	button:Subscribe("Press" , self , self.ModelSelected)
	self.tagToModelButtons[args.tag][args.model] = button
end

function ModelViewerTabs.Tags:RemoveModelButton(args)
	local modelButtons = self.tagToModelButtons[args.tag]
	local modelButton = modelButtons[args.model]
	if modelButton ~= nil then
		if self.activeModelButton == modelButton then
			self.activeModelButton = nil
		end
		modelButton:Remove()
		modelButtons[args.model] = nil
	end
	
	if args.removeTag == true then
		local tagButton = self.tagToTagButton[args.tag]
		
		local modelsContainer = tagButton:GetDataObject("modelsContainer")
		modelsContainer:Remove()
		
		tagButton:Remove()
		self.tagToTagButton[args.tag] = nil
		self.tagToModelButtons[args.tag] = nil
		
		if self.activeTagButton == tagButton then
			self.activeTagButton = nil
		end
	else
		self:UpdateTag(args.tag)
	end
end

function ModelViewerTabs.Tags:UpdateTag(tag)
	local tagButton = self.tagToTagButton[tag]
	local models = MapEditor.taggedModels[tag]
	tagButton:SetText(string.format("(%d) %s" , #models , tag))
	
	local modelsContainer = tagButton:GetDataObject("modelsContainer")
	modelsContainer:SetHeight(#models * self.modelButtonHeight)
end

function ModelViewerTabs.Tags:SortTagButtons()
	local tags = {}
	
	for tag , tagButton in pairs(self.tagToTagButton) do
		table.insert(tags , tag)
	end
	
	table.sort(tags , function(a , b)
		return a:lower() < b:lower()
	end)
	
	for index , tag in ipairs(tags) do
		self.tagToTagButton[tag]:BringToFront()
	end
end

function ModelViewerTabs.Tags:SortModelButtons(tag)
	local namedModels = {}
	local unnamedModels = {}
	
	local modelButtons = self.tagToModelButtons[tag]
	for model , modelButton in pairs(modelButtons) do
		if MapEditor.modelNames[model] ~= nil then
			table.insert(namedModels , model)
		else
			table.insert(unnamedModels , model)
		end
	end
	
	table.sort(namedModels , function(a , b)
		return MapEditor.modelNames[a]:lower() < MapEditor.modelNames[b]:lower()
	end)
	
	table.sort(unnamedModels)
	
	for index , model in ipairs(namedModels) do
		modelButtons[model]:BringToFront()
	end
	for index , model in ipairs(unnamedModels) do
		modelButtons[model]:BringToFront()
	end
end

-- Network events

function ModelViewerTabs.Tags:ReceiveTaggedModels(taggedModels)
	MapEditor.taggedModels = taggedModels
	MapEditor.modelToTags = {}
	
	-- Makes it so you can do: local models = MapEditor.taggedModels["Some Tag"]
	for index , tagEntry in ipairs(MapEditor.taggedModels) do
		MapEditor.taggedModels[tagEntry[1]] = tagEntry[2]
	end
	
	-- Makes it so you can do, local tags = MapEditor.modelToTags["SomeModel.lod"]
	for index , tagEntry in ipairs(MapEditor.taggedModels) do
		local tag = tagEntry[1]
		local models = tagEntry[2]
		
		for index , model in ipairs(models) do
			if MapEditor.modelToTags[model] ~= nil then
				table.insert(MapEditor.modelToTags[model] , tag)
			else
				MapEditor.modelToTags[model] = {tag}
			end
		end
	end
	
	self.tagsArea:RemoveAllChildren()
	
	for index , tagEntry in ipairs(MapEditor.taggedModels) do
		self:AddTagButton{tag = tagEntry[1] , models = tagEntry[2]}
	end
	self:SortTagButtons()
end

-- GWEN events

function ModelViewerTabs.Tags:TagSelected(tagButton)
	if self.activeTagButton ~= nil then
		self.activeTagButton:SetTextNormalColor(self.colors.textNormal)
		self.activeTagButton:SetTextHoveredColor(self.colors.textHovered)
		self.activeTagButton:SetTextColor(self.colors.textNormal)
		local modelsContainer = self.activeTagButton:GetDataObject("modelsContainer")
		modelsContainer:SetVisible(false)
	end
	
	self.activeTagButton = tagButton
	tagButton:SetTextNormalColor(self.colors.textSelected)
	tagButton:SetTextHoveredColor(self.colors.textSelectedHovered)
	
	local modelsContainer = tagButton:GetDataObject("modelsContainer")
	
	local hasLoadedModels = tagButton:GetDataBool("hasLoadedModels")
	if hasLoadedModels == false then
		tagButton:SetDataBool("hasLoadedModels" , true)
		local tag = tagButton:GetDataString("tag")
		local models = MapEditor.taggedModels[tag]
		
		for index , model in ipairs(models) do
			self:AddModelButton{tag = tag , model = model}
		end
		
		self:SortModelButtons(tag)
		
		modelsContainer:SetHeight(#models * self.modelButtonHeight)
	end
	
	modelsContainer:SetVisible(true)
end

function ModelViewerTabs.Tags:ModelSelected(modelButton)
	if self.activeModelButton ~= nil then
		self.activeModelButton:SetTextNormalColor(self.colors.textNormal)
		self.activeModelButton:SetTextHoveredColor(self.colors.textHovered)
		self.activeModelButton:SetTextColor(self.colors.textNormal)
	end
	
	self.activeModelButton = modelButton
	modelButton:SetTextNormalColor(self.colors.textSelected)
	modelButton:SetTextHoveredColor(self.colors.textSelectedHovered)
	
	self.modelViewer:SetModelPath(modelButton:GetDataString("model"))
	self.modelViewer:SpawnStaticObject()
end
