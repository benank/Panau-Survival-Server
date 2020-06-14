TOKEN = var(" ")

Network:Subscribe(var("HitDetection/UpdateToken"):get(), function(args)
    TOKEN:set(args.token)
end)