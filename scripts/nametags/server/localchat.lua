Events:Subscribe("PlayerChat", function(args)
    if args.text == "/local" then
        args.player:SetValue("LocalChat", not args.player:GetValue("LocalChat"))

        if args.player:GetValue("LocalChat") then
            Chat:Send(args.player, "Local Chat enabled.", Color.Yellow)
        else
            Chat:Send(args.player, "Local Chat disabled.", Color.Yellow)
        end
    end
end)