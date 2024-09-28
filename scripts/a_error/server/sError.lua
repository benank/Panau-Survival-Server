Events:Subscribe("ModuleError", function(e)
    local error = FormatError(e, "SERVER ERROR")

    Events:Fire("Discord", {
        channel = "Errors",
        content = error
    })
end)

Network:Subscribe("ModuleError", function(args, player)

    if args.error.find("module build") then
        player:Kick("Please restart your game in order to play on the server.")
        print(string.format("Kicked player %s (%s) due to build errors", player:GetName(), player:GetSteamId()))
    end

    Events:Fire("Discord", {
        channel = "Errors",
        content = tostring(args.error)
    })
end)