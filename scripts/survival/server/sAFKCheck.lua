Events:Subscribe("ClientModuleLoad", function(args)
    args.player:SetValue("LastAFKTime", Server:GetElapsedSeconds())
end)

Events:Subscribe("MinuteTick", function()
    local currentTime = Server:GetElapsedSeconds()
    for p in Server:GetPlayers() do
       local lastafktime = p:GetValue("LastAFKTime")
       
       if lastafktime then
            local timeElapsed = currentTime - lastafktime
            
            if timeElapsed > 120 then
                p:Kick("AFK timer")
            elseif timeElapsed > 60 then
                Network:Send(p, "AFKCheck")
            end
        
       end
    end
end)

Network:Subscribe("AFKCheck", function(args, player)
    player:SetValue("LastAFKTime", Server:GetElapsedSeconds())
end)