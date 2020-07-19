MapEditor.VersionConversion = {}

MapEditor.VersionConversion.Convert = function(marshalledSource)
	if marshalledSource.version == MapEditor.version then
		return marshalledSource
	end
	
	if marshalledSource.version > MapEditor.version then
		return {error = "Map version is higher than editor version. Update your map editor!"}
	end
	
	for n = marshalledSource.version , MapEditor.version - 1 do
		print("Updating map from version "..n.." to "..(n + 1))
		marshalledSource = MapEditor.VersionConversion.ConversionFunctions[n](marshalledSource)
	end
	print("Done")
	
	marshalledSource.version = MapEditor.version
	
	return marshalledSource
end

MapEditor.VersionConversion.ConversionFunctions = {
	[2] = function(marshalledSource)
		-- Nothing to do here. Only some object properties were added, which get fixed automatically
		-- on the client.
		return marshalledSource
	end ,
	[3] = function(marshalledSource)
		-- Nothing to do here. Two properties were added to Racing. I know it's awkward to increase
		-- the version just because of a small map type change. Maybe there should be two versions in
		-- each map: the map version and the map type (Racing) version.
		return marshalledSource
	end ,
	[4] = function(marshalledSource)
		-- Nothing to do here. One property was added to Racing. I just realized: the marshalledSource
		-- table has the funky property stuff going on where it stores the hash of the name and
		-- whether it's a table, which would be annoying to work with here. Could maybe add utility
		-- functions, like ChangePropertyName, but... bleh.
		return marshalledSource
	end ,
}
