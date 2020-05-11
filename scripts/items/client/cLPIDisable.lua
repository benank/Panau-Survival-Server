local blacklist = {
    [Action.UseItem] = true,
}

Events:Subscribe("LocalPlayerInput", function(args)
    if blacklist[args.input] then return false end
end)