Events:Subscribe("PlayerChat", function(args) 
	if args.text == "/coords" then
		args.player:SendChatMessage(tostring(args.player:GetPosition()), Color.Aqua)
		print(tostring(args.player:GetPosition()))
	end
end)