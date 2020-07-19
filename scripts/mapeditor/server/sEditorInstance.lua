MapEditor.playerIdToWorld = {}

MapEditor.CreateWorldForPlayerIfNotExists = function(player)
	if MapEditor.playerIdToWorld[player:GetId()] ~= nil then
		return
	end
	
	local world = World.Create()
	MapEditor.playerIdToWorld[player:GetId()] = world
	world:SetTime(12)
	world:SetTimeStep(0)
	world:SetWeatherSeverity(0)
	player:SetWorld(world)
end

-- Events

Events:Subscribe("ClientModuleLoad" , function(args)
	MapEditor.CreateWorldForPlayerIfNotExists(args.player)
end)

Events:Subscribe("PlayerQuit" , function(args)
	local world = MapEditor.playerIdToWorld[args.player:GetId()]
	MapEditor.playerIdToWorld[args.player:GetId()] = nil
	world:Remove()
end)

-- Network events

Network:Subscribe("SetTimeOfDay" , function(time , player)
	MapEditor.CreateWorldForPlayerIfNotExists(player)
	
	local world = MapEditor.playerIdToWorld[player:GetId()]
	world:SetTime(time)
end)

Network:Subscribe("SetWeather" , function(weather , player)
	MapEditor.CreateWorldForPlayerIfNotExists(player)
	
	local world = MapEditor.playerIdToWorld[player:GetId()]
	world:SetWeatherSeverity(weather)
end)
