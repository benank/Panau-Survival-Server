-- Unload some modules only for testing

Events:Subscribe("ServerStart", function()
    Console:Run("unload effects")
    Console:Run("unload LocalizedWeather")
    Console:Run("unload modelviewer")
    Console:Run("unload settings")
end)