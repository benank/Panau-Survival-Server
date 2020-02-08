Events:Subscribe("LocalPlayerChat", function(args)

	if args.text:find("/event") then
		Game:FireEvent(string.sub(args.text, 8))
	end

end)