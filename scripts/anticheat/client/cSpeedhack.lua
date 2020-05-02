local start_time = os.time()
local timer = Timer()

local func = coroutine.wrap(function()
    while true do
        
        local time_diff = os.time() - start_time
        local diff = math.abs(timer:GetSeconds() - time_diff)
        if diff > 1 then
            Network:Send(var("Anticheat/Speedhack"):get(), {diff = diff})
        end

        Timer.Sleep(1000)
    end
end)()
