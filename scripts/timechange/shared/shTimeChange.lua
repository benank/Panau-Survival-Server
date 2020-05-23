Thread(function()
    while true do
        Timer.Sleep(1000)
        Events:Fire("SecondTick")
    end
end)

Thread(function()
    while true do
        Timer.Sleep(60 * 1000)
        Events:Fire("MinuteTick")
    end
end)