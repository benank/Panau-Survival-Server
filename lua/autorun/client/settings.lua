Settings = {}

Network:Subscribe("SettingsUpdate", function(args)
    Settings = args.settings
end)