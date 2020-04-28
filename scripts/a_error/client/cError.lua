Events:Subscribe("ModuleError", function(e)
    local error = FormatError(e, string.format("%s %s", LocalPlayer:GetName(), LocalPlayer:GetSteamId()))

    Network:Send("ModuleError", {error = error})
end)