-- TODO: make this more robust
Network:Subscribe("items/Cheating", function(args, player)
    print(player:GetName() .. " was kicked for " .. tostring(args.reason))
    player:Kick("You were kicked for " .. tostring(args.reason))
end)