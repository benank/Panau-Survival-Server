LocalPlayer:SetValue("MeasureMemory", {})
function MeasureMemory(name)
    Thread(function()
        while true do
            local mem = LocalPlayer:GetValue("MeasureMemory")
            mem[name] = tostring(collectgarbage("count"))
            LocalPlayer:SetValue("MeasureMemory", mem)
            Timer.Sleep(1000)
        end
    end)
     
end