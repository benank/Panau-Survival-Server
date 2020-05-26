Timer.SetInterval(1000, function()
    --while true do
        --Timer.Sleep(1000)
        Events:Fire("SecondTick")
    --end
end)

Timer.SetInterval(60 * 1000, function()
    --while true do
        --Timer.Sleep(60 * 1000)
        Events:Fire("MinuteTick")
    --end
end)