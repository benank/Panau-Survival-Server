-- Manages model names and tags.

MapEditor.modelNames = {}

MapEditor.taggedModels = {}
MapEditor.tagToModels = {}
MapEditor.modelToTagEntries = {}

MapEditor.ModelDataManager = {}

MapEditor.ModelDataManager.modelNamesPath = "ModelNames.txt"
MapEditor.ModelDataManager.modelTagsPath = "ModelTags.txt"

MapEditor.ModelDataManager.WriteNamesToDisk = function()
	local file = io.open(MapEditor.ModelDataManager.modelNamesPath , "w")
	local jsonString = JSON:encode(MapEditor.modelNames)
	file:write(jsonString)
	file:close()
end

MapEditor.ModelDataManager.WriteTagsToDisk = function()
	local file = io.open(MapEditor.ModelDataManager.modelTagsPath , "w")
	local jsonString = JSON:encode(MapEditor.taggedModels)
	-- jsonString = jsonString:gsub("%]%],%[" , "]],\n["):gsub("," , ",\n  ")
	file:write(jsonString)
	file:close()
end

Events:Subscribe("ModuleLoad" , function()
	-- Get MapEditor.modelNames.
	local file , openError = io.open(MapEditor.ModelDataManager.modelNamesPath , "r")
	if openError then
		warn("Cannot open model names file: "..openError)
		return
	end
	local entireFile = file:read("*a")
	file:close()
	MapEditor.modelNames = JSON:decode(entireFile)
	-- Get MapEditor.taggedModels.
	local file , openError = io.open(MapEditor.ModelDataManager.modelTagsPath , "r")
	if openError then
		warn("Cannot open model tags file: "..openError)
		return
	end
	local entireFile = file:read("*a")
	file:close()
	MapEditor.taggedModels = JSON:decode(entireFile)
	-- Makes it so you can do: local models = MapEditor.tagToModels["Some Tag"]
	MapEditor.tagToModels = {}
	for index , tagEntry in ipairs(MapEditor.taggedModels) do
		MapEditor.tagToModels[tagEntry[1]] = tagEntry[2]
	end
	-- Makes it so you can do, local tagEntries = MapEditor.modelToTagEntries["SomeModel.lod"]
	MapEditor.modelToTagEntries = {}
	for index , tagEntry in ipairs(MapEditor.taggedModels) do
		local tag = tagEntry[1]
		local models = tagEntry[2]
		
		for index , model in ipairs(models) do
			if MapEditor.modelToTagEntries[model] ~= nil then
				MapEditor.modelToTagEntries[model][tag] = tagEntry
			else
				MapEditor.modelToTagEntries[model] = {tag = tagEntry}
			end
		end
	end
end)

Network:Subscribe("RequestModelNames" , function(unused , player)
	Network:Send(player , "ReceiveModelNames" , MapEditor.modelNames)
end)

Network:Subscribe("SetModelName" , function(args , player)
	if args.name:len() == 0 then
		MapEditor.modelNames[args.model] = nil
		args.name = nil
	else
		MapEditor.modelNames[args.model] = args.name
	end
	
	Network:Broadcast("ReceiveModelName" , args)
	
	MapEditor.ModelDataManager.WriteNamesToDisk()
end)

Network:Subscribe("RequestTaggedModels" , function(unused , player)
	Network:Send(player , "ReceiveTaggedModels" , MapEditor.taggedModels)
end)

Network:Subscribe("TaggedModelAdd" , function(args , player)
	local models = MapEditor.tagToModels[args.tag]
	-- If the tag doesn't exist, create it.
	if models == nil then
		models = {}
		local tagEntry = {args.tag , models}
		table.insert(MapEditor.taggedModels , tagEntry)
		MapEditor.tagToModels[args.tag] = models
	end
	
	local tagEntries = MapEditor.modelToTagEntries[args.model]
	-- If MapEditor.modelToTagEntries doesn't have the model yet, add it.
	if tagEntries == nil then
		tagEntries = {}
		MapEditor.modelToTagEntries[args.model] = tagEntries
	end
	
	if table.find(models , args.model) ~= nil then
		print("      Tag: "..args.tag)
		print("    Model: "..args.model)
		error("Already have tagged model!")
	else
		-- #1 Add model to MapEditor.taggedModels (and MapEditor.tagToModels).
		table.insert(models , args.model)
		-- #2 Add tag to MapEditor.modelToTagEntries.
		for index = #MapEditor.taggedModels , 1 , -1 do
			local tagEntry = MapEditor.taggedModels[index]
			if tagEntry[1] == args.tag then
				tagEntries[args.tag] = tagEntry
				break
			end
		end
	end
	
	Network:Broadcast("ReceiveTaggedModelAdd" , args)
	
	MapEditor.ModelDataManager.WriteTagsToDisk()
end)

Network:Subscribe("TaggedModelRemove" , function(args , player)
	local models = MapEditor.tagToModels[args.tag]
	if models == nil then
		print("      Tag: "..args.tag)
		print("    Model: "..args.model)
		error("Tag doesn't exist!")
	end
	-- #1 Remove model from MapEditor.taggedModels (and MapEditor.tagToModels).
	local findResult = table.find(models , args.model)
	if findResult then
		table.remove(models , findResult)
	end
	local isLastModel = #models == 0
	-- #2 Remove tag from MapEditor.modelToTagEntries.
	local tagEntry
	for index = #MapEditor.taggedModels , 1 , -1 do
		tagEntry = MapEditor.taggedModels[index]
		if tagEntry[1] == args.tag then
			local tagEntries = MapEditor.modelToTagEntries[args.model]
			tagEntries[args.tag] = nil
			-- If this was the last model with this tag, remove the tag entry.
			if isLastModel then
				table.remove(MapEditor.taggedModels , index)
				MapEditor.tagToModels[args.tag] = nil
			end
			break
		end
	end
	
	Network:Broadcast("ReceiveTaggedModelRemove" , args)
	
	MapEditor.ModelDataManager.WriteTagsToDisk()
end)
