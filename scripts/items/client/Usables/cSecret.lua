Network:Subscribe("items/SyncSecrets", function(args)
    Events:Fire("items/SyncSecrets", args)
end)

Network:Subscribe("items/RemoveSecret", function(args)
    Events:Fire("items/RemoveSecret", args)
end)

Network:Subscribe("items/NewSecret", function(args)
    Events:Fire("items/NewSecret", args)
end)

