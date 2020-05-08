Events:Subscribe(var("ModuleError"):get(), function(e)
    local error = FormatError(e, string.format("%s %s", LocalPlayer:GetName(), LocalPlayer:GetSteamId()))

    Network:Send(var("ModuleError"):get(), {error = error})
end)