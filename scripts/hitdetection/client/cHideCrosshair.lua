Events:Subscribe("LocalPlayerChat", function(args)
    if args.text == "/nocrosshair" then
        Game:FireEvent("gui.crosshair.hide")
        Game:FireEvent("gui.aim.hide")
    end
end)