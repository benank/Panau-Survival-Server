class("AllModels" , ModelViewerTabs)

function ModelViewerTabs.AllModels:__init(modelViewer)
	self.modelViewer = modelViewer
	
	self.colors = {
		modelRow =                 Color(136 , 136 , 136 , 26) ,
		modelText =                Color(216 , 216 , 216 , 255) ,
		modelTextHovered =         Color(255 , 255 , 255 , 255) ,
		modelTextSelected =        Color(240 , 234 , 160 , 255) ,
		modelTextSelectedHovered = Color(255 , 246 , 96 , 255) ,
	}
	
	self.page = self.modelViewer.tabControl:AddPage("All models"):GetPage()
	
	self.selectedModelButton = nil
	self.modelPathToModelButton = {}
	
	-- If this uses a Tree like the modelviewer script does, it uses 500MB of memory and lags like
	-- crazy. This is because it creates thousands of controls for each model. This solution loads
	-- the archive names but only loads each archive's models when the archive is expanded.
	local scrollControl = ScrollControl.Create(self.page)
	scrollControl:SetDock(GwenPosition.Fill)
	scrollControl:SetScrollable(false , true)
	
	for index , archiveEntry in ipairs(MapEditor.modelList) do
		local archive = archiveEntry[1]
		local models = archiveEntry[2]
		
		local button = LabelClickable.Create(scrollControl)
		button:SetAlignment(GwenPosition.CenterV)
		button:SetDock(GwenPosition.Top)
		button:SetText(string.format("(%d) %s" , #models , archive))
		button:SizeToContents()
		button:SetHeight(button:GetHeight() + 4)
		button:SetDataString("archive" , archive)
		button:SetDataBool("hasLoadedModels" , false)
		button:Subscribe("Press" , self , self.ArchiveSelected)
		
		local modelsContainer = Rectangle.Create(scrollControl)
		modelsContainer:SetMargin(Vector2(24 , 0) , Vector2(0 , 0))
		modelsContainer:SetDock(GwenPosition.Top)
		modelsContainer:SetColor(self.colors.modelRow)
		modelsContainer:SetVisible(false)
		
		button:SetDataObject("modelsContainer" , modelsContainer)
	end
end

function ModelViewerTabs.AllModels:SetModelName(args)
	local button = self.modelPathToModelButton[args.model]
	if button ~= nil then
		button:SetText(args.name or button:GetDataString("model"))
	end
end

-- GWEN events

function ModelViewerTabs.AllModels:ArchiveSelected(archiveButton)
	local archive = archiveButton:GetDataString("archive")
	
	local hasLoadedModels = archiveButton:GetDataBool("hasLoadedModels")
	local modelsContainer = archiveButton:GetDataObject("modelsContainer")
	
	if hasLoadedModels == false then
		local models = MapEditor.modelList[archive]
		
		local buttonHeight = 16
		
		for index , model in ipairs(models) do
			local modelPath = archive.."/"..model
			
			local button = LabelClickable.Create(modelsContainer)
			button:SetDock(GwenPosition.Top)
			button:SetText(MapEditor.modelNames[modelPath] or model)
			button:SetHeight(buttonHeight)
			button:SetTextNormalColor(self.colors.modelText)
			button:SetTextHoveredColor(self.colors.modelTextHovered)
			button:SetDataString("model" , model)
			button:SetDataString("archive" , archive)
			button:Subscribe("Press" , self , self.ModelSelected)
			
			self.modelPathToModelButton[modelPath] = button
		end
		
		modelsContainer:SetHeight(#models * buttonHeight)
		
		archiveButton:SetDataBool("hasLoadedModels" , true)
	end
	
	modelsContainer:SetVisible(not modelsContainer:GetVisible())
end

function ModelViewerTabs.AllModels:ModelSelected(modelButton)
	if self.selectedModelButton ~= nil then
		self.selectedModelButton:SetTextNormalColor(self.colors.modelText)
		self.selectedModelButton:SetTextHoveredColor(self.colors.modelTextHovered)
		self.selectedModelButton:SetTextColor(self.colors.modelText)
	end
	
	modelButton:SetTextNormalColor(self.colors.modelTextSelected)
	modelButton:SetTextHoveredColor(self.colors.modelTextSelectedHovered)
	self.selectedModelButton = modelButton
	
	local model = modelButton:GetDataString("model")
	local archive = modelButton:GetDataString("archive")
	
	self.modelViewer:SetModelPath(archive.."/"..model)
	self.modelViewer:SpawnStaticObject()
end
