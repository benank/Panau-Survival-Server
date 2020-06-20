class 'sServerStats'

function sServerStats:__init()

    self.stats = 
    {
        ["PlayersOnline"] = 0
    }

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

end

function sServerStats:ClientModuleLoad(args)
    self.stats["PlayersOnline"] = Server:GetPlayerCount()
    self:RefreshOnlinePlayers()
end

function sServerStats:PlayerQuit(args)
    Timer.SetTimeout(1000, function()
        self.stats["PlayersOnline"] = Server:GetPlayerCount()
        self:RefreshOnlinePlayers()
    end)
end

function sServerStats:RefreshOnlinePlayers()
    Network:Broadcast("ServerStats/UpdatePlayersOnline", {online = self.stats["PlayersOnline"]})
end

sServerStats = sServerStats()