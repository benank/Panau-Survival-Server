MapEditor.MapsList = {}

MapEditor.MapsList.mapsDirectory = "Maps/"

Network:Subscribe("RequestMapList" , function(unused , player)
	local fileNames = io.files(MapEditor.MapsList.mapsDirectory)
	local mapNames = {}
	
	for index , fileName in ipairs(fileNames) do
		if fileName:sub(-4) == ".map" then
			table.insert(mapNames , fileName:sub(1 , -5))
		end
	end
	
	Network:Send(player , "ReceiveMapList" , mapNames)
end)

Network:Subscribe("SaveMap" , function(args , player)
	print(player:GetName().." is saving map: "..args.name)
	-- Convert the object table's keys to strings so that the json library doesn't fill up the gaps
	-- between ids with "null, null, null, " spam.
	local objectsWithStringKeys = {}
	for index , object in pairs(args.marshalledSource.objects) do
		objectsWithStringKeys[tostring(index)] = object
	end
	args.marshalledSource.objects = objectsWithStringKeys
	
	io.createdir(MapEditor.MapsList.mapsDirectory)
	
	local file = io.open(MapEditor.MapsList.mapsDirectory..args.name..".map" , "w")
	file:write(JSON:encode(args.marshalledSource))
	file:close()
	
	Network:Send(player , "ConfirmMapSave")
end)

Network:Subscribe("RequestMap" , function(args , player)
	print(player:GetName().." is loading map: "..args.name)
	
	local path = MapEditor.MapsList.mapsDirectory..args.name..".map"
	local file , openError = io.open(path , "r")
	if openError then
		Network:Send(player , "ReceiveMap" , nil)
		error("Cannot load "..tostring(path)..": "..openError)
	end
	
	local entireFile = file:read("*a")
	file:close()
	
	local marshalledSource = JSON:decode(entireFile)
	-- If the map's version differs from our version, convert it.
	if marshalledSource.version ~= MapEditor.version then
		marshalledSource = MapEditor.VersionConversion.Convert(marshalledSource)
	end
	
	Network:Send(player , "ReceiveMap" , marshalledSource)
end)

Console:Subscribe("convertallmaps" , function()
	local fileNames = io.files(MapEditor.MapsList.mapsDirectory)
	for index , fileName in ipairs(fileNames) do
		local file , openError = io.open(MapEditor.MapsList.mapsDirectory..fileName)
		if openError == nil then
			local entireFile = file:read("*a")
			local marshalledSource = JSON:decode(entireFile)
			-- If the map's version differs from our version, convert it.
			if marshalledSource.version ~= MapEditor.version then
				print("Converting "..fileName)
				marshalledSource = MapEditor.VersionConversion.Convert(marshalledSource)
				file:close()
				file , openError = io.open(MapEditor.MapsList.mapsDirectory..fileName , "w")
				if openError == nil then
					file:write(JSON:encode_pretty(marshalledSource))
				end
			end
		end
		file:close()
	end
end)
