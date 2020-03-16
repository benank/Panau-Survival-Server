class 'sAntiCheat'

function sAntiCheat:__init()

    Network:Subscribe("anticheat/collisioncheck", self, self.CollisionCheck)
end

function sAntiCheat:CollisionCheck(args, player)
    player:Kick("Please restart your game in order to play on the server.")
end

sAntiCheat = sAntiCheat()