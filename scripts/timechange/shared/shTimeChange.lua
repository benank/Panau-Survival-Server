Timer.SetInterval(1000, function()
    Events:Fire("SecondTick")
end)

Timer.SetInterval(60 * 1000, function()
    Events:Fire("MinuteTick")
end)