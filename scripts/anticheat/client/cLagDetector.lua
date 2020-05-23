Thread(function()
    while true do
        Network:Send(var("Anticheat/LagCheck"):get())
        Timer.Sleep(3000)
    end
end)

