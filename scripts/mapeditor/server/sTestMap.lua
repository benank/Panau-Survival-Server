Network:Subscribe("TestMap" , function(args , player)
	local eventArgs = {
		mapType = args.mapType ,
		players = {player} ,
		marshalledMap = args.marshalledMap ,
	}
	Events:Fire("TestMap" , eventArgs)
end)
