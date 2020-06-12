Events:Subscribe("ClientModuleLoad", function(args)
    args.source = "inventory"
    Events:Fire("LoadFlowAdd", args)
end)