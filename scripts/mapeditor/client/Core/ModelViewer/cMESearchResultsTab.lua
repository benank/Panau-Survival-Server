class("SearchResults" , ModelViewerTabs)

function ModelViewerTabs.SearchResults:__init(modelViewer)
	self.modelViewer = modelViewer
	
	self.tabButton = self.modelViewer.tabControl:AddPage("Search Results")
	self.page = self.tabButton:GetPage()
	
	self.textSize = 12
	
	local label = Label.Create(self.page)
	label:SetDock(GwenPosition.Fill)
	label:SetText("No results")
	self.noResultsLabel = label
	
	local scrollControl = ScrollControl.Create(self.page)
	scrollControl:SetScrollable(false , true)
	scrollControl:SetDock(GwenPosition.Fill)
	scrollControl:SetVisible(false)
	self.resultsArea = scrollControl
end

function ModelViewerTabs.SearchResults:Search(searchText)
	local words = searchText:lower():split(" ")
	
	-- Key: model (string)
	-- Value: score (number)
	-- Higher scores are placed higher in the result list.
	local modelScores = {}
	
	local AddScore = function(model , score)
		local currentScore = modelScores[model]
		if currentScore ~= nil then
			modelScores[model] = currentScore + score
		else
			modelScores[model] = score
		end
		
		-- print("Adding score to "..(MapEditor.modelNames[model] or model))
	end
	
	for index , searchWord in ipairs(words) do
		-- print("searchWord: "..searchWord)
		
		-- Search by custom model name.
		local isSearchWordInName = false
		for model , name in pairs(MapEditor.modelNames) do
			local nameWords = name:lower():gsub("[%(%)]" , ""):split(" ")
			if table.find(nameWords , searchWord) ~= nil then
				isSearchWordInName = true
				
				AddScore(model , 10)
			end
		end
		-- Search by tag, unless the search word was found in the model name. (Helps with model
		-- names such as "Metal box" having too high of a score when searching for "metal".)
		if isSearchWordInName == false then
			for index , tagEntry in ipairs(MapEditor.taggedModels) do
				local tag = tagEntry[1]:lower()
				if self:SuperStringFind(tag , searchWord) then
					local models = tagEntry[2]
					-- Add points to all models with this tag.
					for index , model in ipairs(models) do
						AddScore(model , 10)
					end
				end
			end
		end
	end
	
	-- Create the result list controls.
	
	local sortedModels = {}
	for model , score in pairs(modelScores) do
		-- Only count scores over 0.
		if score > 0 then
			table.insert(sortedModels , model)
		end
	end
	table.sort(sortedModels , function(a , b)
		local scoreA = modelScores[a]
		local scoreB = modelScores[b]
		-- If both scores are the same, sort alphabetically.
		if scoreA == scoreB then
			local nameA = (MapEditor.modelNames[a] or a):lower()
			local nameB = (MapEditor.modelNames[b] or b):lower()
			return nameA < nameB
		else
			return scoreA > scoreB
		end
	end)
	
	-- for index , model in ipairs(sortedModels) do
		-- print(modelScores[model] , MapEditor.modelNames[model] or model)
	-- end
	
	self:Clear()
	
	if #sortedModels == 0 then
		return
	end
	
	self.noResultsLabel:SetVisible(false)
	self.resultsArea:SetVisible(true)
	
	local AddResult = function(model)
		local button = LabelClickable.Create(self.resultsArea)
		button:SetDock(GwenPosition.Top)
		button:SetTextSize(self.textSize)
		button:SetText(MapEditor.modelNames[model] or model)
		button:SetHeight(self.textSize + 4)
		button:SetDataString("model" , model)
		button:Subscribe("Press" , self , self.ResultButtonSelected)
	end
	
	for index , model in ipairs(sortedModels) do
		AddResult(model)
	end
	
	self.resultsArea:SizeToChildren()
end

function ModelViewerTabs.SearchResults:Clear()
	self.noResultsLabel:SetVisible(true)
	self.resultsArea:SetVisible(false)
	
	self.resultsArea:RemoveAllChildren()
end

function ModelViewerTabs.SearchResults:SuperStringFind(a , b)
	return a:find(b , 1 , true) ~= nil or b:find(a , 1 , true) ~= nil
end

-- GWEN events

function ModelViewerTabs.SearchResults:ResultButtonSelected(button)
	local model = button:GetDataString("model")
	
	self.modelViewer:SetModelPath(model)
	self.modelViewer:SpawnStaticObject()
end
