class 'sAntiCheat'

function sAntiCheat:__init()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Network:Subscribe("anticheat/collisioncheck", self, self.CollisionCheck)
    Network:Subscribe("Anticheat/LagCheck", self, self.LagCheck)
    Network:Subscribe("Anticheat/Speedhack", self, self.Speedhack)
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
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Lag check invalid - there was a delay of %d before a response", diff),
            p_reason = "The server was unable to process your request."
        })
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