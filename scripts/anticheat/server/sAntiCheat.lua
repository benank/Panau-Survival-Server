class 'sAntiCheat'

function sAntiCheat:__init()

    Network:Subscribe("anticheat/collisioncheck", self, self.CollisionCheck)
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