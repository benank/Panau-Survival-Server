Events:Subscribe("ModuleError", function(e)
    local error = FormatError(e, "SERVER ERROR")

    Events:Fire("Discord", {
        channel = "Error",
        content = error
    })
end)

Network:Subscribe("ModuleError", function(args, player)
    Events:Fire("Discord", {
        channel = "Error",
        content = tostring(args.error)
    })
end)