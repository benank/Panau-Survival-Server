MapEditor.PreferencesManager = {}

MapEditor.PreferencesManager.saveTimer = Timer()
MapEditor.PreferencesManager.saveInterval = 5

MapEditor.PreferencesManager.SaveSettings = function()
	Network:Send("SavePreferences" , MapEditor.Preferences)
end

Events:Subscribe("PostTick" , function()
	local seconds = MapEditor.PreferencesManager.saveTimer:GetSeconds()
	if seconds >= MapEditor.PreferencesManager.saveInterval then
		MapEditor.PreferencesManager.saveTimer:Restart()
		MapEditor.PreferencesManager.SaveSettings()
	end
end)

Events:Subscribe("ModuleUnload" , MapEditor.PreferencesManager.SaveSettings)

Network:Subscribe("ReceivePreferences" , function(preferencesString)
	if preferencesString == "EMPTY" then
		return
	end
	
	local marshalledPreferences = preferencesString:split("\n")
	marshalledPreferences[#marshalledPreferences] = nil
	for index , marshalledPreference in ipairs(marshalledPreferences) do
		local tokens = marshalledPreference:split("\t")
		local name = tokens[1]
		local valueType = tokens[2]
		local value = tokens[3]
		
		if valueType == "number" then
			value = tonumber(value)
		elseif valueType == "boolean" then
			value = value == "true"
		end
		
		MapEditor.Preferences[name] = value
	end
	
	MapEditor.preferencesMenu:UpdateValues()
end)
