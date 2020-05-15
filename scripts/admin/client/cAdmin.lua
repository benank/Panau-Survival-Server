Network:Subscribe(var("SetCameraPos"):get(), function(args)
    Events:Fire("SetFreecamPosition", {position = args.pos, player = args.player})
end)