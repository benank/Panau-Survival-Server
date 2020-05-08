Network:Subscribe(var("SetCameraPos"):get(), function(args)
    Events:Fire("SetFreecamPosition", {position = args.pos})
end)