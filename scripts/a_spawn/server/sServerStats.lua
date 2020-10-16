class 'sServerStats'

function sServerStats:__init()

    self.stats = 
    {
        ["PlayersOnline"] = 0,
        ["LootSpawns"] = "0/0",
        ["Drones"] = 0
    }

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("Inventory/UpdateTotalLootSpawns", self, self.UpdateTotalLootSpawns)
    Events:Subscribe("Drones/UpdateTotalDrones", self, self.UpdateTotalDrones)

end

function sServerStats:UpdateTotalDrones(args)
    self.stats["Drones"] = args.drones
    self:Refresh()
end

function sServerStats:UpdateTotalLootSpawns(args)
    self.stats["LootSpawns"] = string.format("%d/%d", args.spawned, args.total)
    self:Refresh()
end

function sServerStats:ClientModuleLoad(args)
    self.stats["PlayersOnline"] = Server:GetPlayerCount()
    self:Refresh()
end

function sServerStats:PlayerQuit(args)
    Timer.SetTimeout(1000, function()
        self.stats["PlayersOnline"] = Server:GetPlayerCount()
        self:Refresh()
    end)
end

function sServerStats:Refresh()
    Network:Broadcast("ServerStats/Update", {stats = self.stats})
end

sServerStats = sServerStats()