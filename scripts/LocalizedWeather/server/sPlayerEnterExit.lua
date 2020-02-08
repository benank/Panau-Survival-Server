
function PlayerEnterStorm(args, player)

    print("Player entered storm")
    player:SetWeatherSeverity(2)

end

function PlayerExitStorm(args, player)

    print("Player exited storm")
    player:SetWeatherSeverity(0)

end

function ModuleUnload()

    for player in Server:GetPlayers() do

        player:SetWeatherSeverity(0)

    end

end

Network:Subscribe("PlayerEnterStorm", PlayerEnterStorm)
Network:Subscribe("PlayerExitStorm", PlayerExitStorm)
Events:Subscribe("ModuleUnload", ModuleUnload)
