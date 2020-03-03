function join(args)
	Game:ShowPopup(args.player:GetName().." joined.", false)
end
Events:Subscribe("PlayerJoin", join)
function leave(args)
	Game:ShowPopup(args.player:GetName().." left.", false)
end
Events:Subscribe("PlayerQuit", leave)
-- FC code