Events:Subscribe("PlayerDeath", function(args)
    Network:Broadcast("PlayerDiedEffect")
end)