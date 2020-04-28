Events:Subscribe("ModuleError", function(e)
    local error = FormatError(e, "SERVER ERROR")

    print("SERVER EROR")
    print(error)
    Events:Fire("Discord", {
        channel = "Error",
        content = error
    })
end)

Network:Subscribe("ModuleError", function(args, player)
    print("CLIENT ERROR")
    print(args.error)
    Events:Fire("Discord", {
        channel = "Error",
        content = tostring(args.error)
    })
end)