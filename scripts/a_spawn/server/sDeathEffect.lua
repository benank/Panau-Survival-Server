Events:Subscribe("PlayerKilled", function(args)
    Network:Broadcast("PlayerDiedEffect")
end)