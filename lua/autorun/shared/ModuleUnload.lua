Events:Subscribe("ModuleUnload", function()
    Events:Fire("ModuleUnloadGlobal")
end)

Events:Subscribe("ModuleLoad", function()
    Events:Fire("ModuleLoadGlobal")
end)