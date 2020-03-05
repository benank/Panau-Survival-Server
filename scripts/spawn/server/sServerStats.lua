class 'sServerStats'

function sServerStats:__init()

    self.stats = 
    {
        ["PlayersOnline"] = 0
    }

    self:RefreshOnlinePlayers()

    Events:Subscribe("ClientModuleLoad", self, self.RefreshOnlinePlayers)
    Events:Subscribe("PlayerQuit", self, self.RefreshOnlinePlayers)

end

function sServerStats:RefreshOnlinePlayers()
    local count = 0
    for p in Server:GetPlayers() do count = count + 1 end
    self.stats["PlayersOnline"] = count
    Network:Broadcast("ServerStats/UpdatePlayersOnline", {online = self.stats["PlayersOnline"]})
end

sServerStats = sServerStats()