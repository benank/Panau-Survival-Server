Events:Subscribe("PlayerChat", function(args)
    if args.text == "/suicide" then
        args.player:Damage(1000)
    end
end)