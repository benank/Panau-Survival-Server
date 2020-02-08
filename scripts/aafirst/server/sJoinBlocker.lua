local all_modules_loaded = 1
local first_load = true

Events:Subscribe("ModuleUnloadGlobal", function()
    if first_load then return end
    all_modules_loaded = all_modules_loaded + 1
end)

Events:Subscribe("ModuleLoadGlobal", function()
    if first_load then return end
    all_modules_loaded = all_modules_loaded - 1
end)

Events:Subscribe("ServerStart", function()
    all_modules_loaded = all_modules_loaded - 1
    first_load = false
end)

Events:Subscribe("PlayerJoin", function(args)
    if all_modules_loaded ~= 0 or first_load then
        args.player:Kick("Sorry, the server is still loading. Please try again in a few seconds.")
    end
end)