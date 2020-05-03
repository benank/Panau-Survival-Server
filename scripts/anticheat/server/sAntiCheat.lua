class 'sAntiCheat'

function sAntiCheat:__init()

    self:CheckServerHealth()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Network:Subscribe("anticheat/collisioncheck", self, self.CollisionCheck)
    Network:Subscribe("Anticheat/LagCheck", self, self.LagCheck)
    Network:Subscribe("Anticheat/Speedhack", self, self.Speedhack)
end

function sAntiCheat:CheckServerHealth()
    
    -- Check to see if the server is lagging
    local func = coroutine.wrap(function()
        local last_time = Server:GetElapsedSeconds()
        local players_history = {}
        
        while true do

            Timer.Sleep(1000)

            local players = {}

            for p in Server:GetPlayers() do
                players[p:GetId()] = p
            end

            local seconds_elapsed = Server:GetElapsedSeconds()

            if seconds_elapsed - last_time > 2 then

                local msg = string.format("**Hitch warning: Server is running %.2f seconds behind!**", seconds_elapsed - last_time)
                print(msg)

                Events:Fire("Discord", {
                    channel = "Errors",
                    content = msg
                })

                local players_msg = "Players Online:"

                local last_players = players_history[tostring(string.format("%.0f", last_time))]

                if last_players then
                    for id, p in pairs(last_players) do
                        if IsValid(p) then
                            players_msg = players_msg .. "\n" .. string.format("%s [%s] [%s]", p:GetName(), p:GetSteamId(), p:GetIP())
                        end
                    end

                    print(players_msg)

                    Events:Fire("Discord", {
                        channel = "Errors",
                        content = players_msg
                    })
                end

            end

            -- Erase old players
            players_history[tostring(string.format("%.0f", last_time))] = nil

            last_time = seconds_elapsed

            -- Add new players
            players_history[tostring(string.format("%.0f", last_time))] = players

        end
    end)()

end

function sAntiCheat:Speedhack(args, player)

    Events:Fire("KickPlayer", {
        player = player,
        reason = string.format("Speedhack - difference of %.2f detected", args.diff),
        p_reason = "Something went wrong. Please restart your game."
    })

end

function sAntiCheat:ClientModuleLoad(args)
    args.player:SetValue("LastLagCheck", Server:GetElapsedSeconds())
end

function sAntiCheat:LagCheck(args, player)

    local last_check = player:GetValue("LastLagCheck")

    if not last_check then return end

    local diff = Server:GetElapsedSeconds() - last_check

    if diff < 2 then
        Events:Fire("KickPlayer", {
            player = player,
            reason = "Lag check invalid - response sent too quickly",
            p_reason = "The server was unable to process your request."
        })
        return
    end

    if diff > 6 then
        Timer.SetTimeout(2000, function()
            if IsValid(player) then
                Events:Fire("KickPlayer", {
                    player = player,
                    reason = string.format("Lag check invalid - there was a delay of %d before a response", diff),
                    p_reason = "The server was unable to process your request."
                })
            end
        end)
        return
    end

    player:SetValue("LastLagCheck", Server:GetElapsedSeconds())

end

function sAntiCheat:CollisionCheck(args, player)
    player:Kick("Please restart your game in order to play on the server.")
    
    local msg = string.format("Player %s [%s] kicked for invalid collision", player:GetName(), player:GetSteamId())
    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })
end

sAntiCheat = sAntiCheat()