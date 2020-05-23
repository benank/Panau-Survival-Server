Events:Subscribe("LocalPlayerChat", function(args)
    if args.text == "/npc" then
        local npc = ClientActor.Create(AssetLocation.Game, {model_id = 39, position = LocalPlayer:GetPosition(), angle = Angle()})
    end
end)