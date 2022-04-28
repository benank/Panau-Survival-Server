Events:Subscribe("ClientModuleLoad", function(args)
    args.player:SetValue("LastAFKTime", Server:GetElapsedSeconds())
    args.player:SetValue("AFKTimerCount", 0)
end)

Events:Subscribe("MinuteTick", function()
    local currentTime = Server:GetElapsedSeconds()
    for p in Server:GetPlayers() do
       local lastafktime = p:GetValue("LastAFKTime")
       
       if lastafktime then
            local timeElapsed = currentTime - lastafktime
            
            if timeElapsed > 120 then
                p:SetValue("AFKTimerCount", p:GetValue("AFKTimerCount") + 1)
            elseif timeElapsed > 60 then
                Network:Send(p, "AFKCheck")
            end
            
            if p:GetValue("AFKTimerCount") > 5 then
                p:Kick("AFK Timer")
            end
       end
    end
end)

Network:Subscribe("AFKCheck", function(args, player)
    player:SetValue("LastAFKTime", Server:GetElapsedSeconds())
    player:SetValue("AFKTimerCount", 0)
end)