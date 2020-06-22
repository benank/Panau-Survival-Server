Events:Subscribe("ModuleLoad", function()

    if not BUILDING_ENABLED then return end

    sBuildCommands = sBuildCommands()

end)