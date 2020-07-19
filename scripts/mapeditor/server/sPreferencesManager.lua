Events:Subscribe("ModuleLoad" , function()
	SQL:Execute[[
		create table if not exists MapEditorPreferences(
			SteamId            integer primary key ,
			PreferencesString  text
		)
	]]
end)

Events:Subscribe("ClientModuleLoad" , function(args)
	MapEditor.SendPreferencesToPlayer(args.player)
end)

MapEditor.SendPreferencesToPlayer = function(player)
	local query = SQL:Query[[
		select PreferencesString from MapEditorPreferences where SteamId = ?
	]]
	query:Bind(1 , player:GetSteamId().id)
	local result = query:Execute()[1]
	if result == nil then
		Network:Send(player , "ReceivePreferences" , "EMPTY")
	else
		Network:Send(player , "ReceivePreferences" , result.PreferencesString)
	end
end

Network:Subscribe("SavePreferences" , function(newPreferences , player)
	local text = ""
	
	for name , value in pairs(newPreferences) do
		local typeString = type(value)
		if typeString == "userdata" then
			typeString = value.__type or typeString
		end
		
		local valueString = tostring(value) or "INVALID"
		
		text = text..name.."\t"..typeString.."\t"..valueString.."\n"
	end
	
	local command = SQL:Command[[
		insert or replace into MapEditorPreferences(SteamId , PreferencesString)
		values(?,?)
	]]
	command:Bind(1 , player:GetSteamId().id)
	command:Bind(2 , text)
	command:Execute()
end)

Network:Subscribe("RequestPreferences" , MapEditor.SendPreferencesToPlayer)
