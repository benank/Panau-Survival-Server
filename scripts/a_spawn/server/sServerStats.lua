class 'sServerStats'

function sServerStats:__init()

    self.stats = 
    {
        ["PlayersOnline"] = 0,
        ["LootSpawns"] = "0/0",
        ["Drones"] = 0,
        ["Vehicles"] = "0/0",
        ["UniquePlayers"] = 0,
        ["BoxesLooted"] = 0,
        ["DronesDestroyed"] = 0,
        ["TotalKills"] = 0,
        ["TotalDeaths"] = 0,
        ["BuildObjects"] = 0,
        ["TotalStashes"] = 0,
        ["PlacedExplosives"] = 0
    }
    
    self:RefreshStats()
    Timer.SetInterval(1000 * 60 * 60 * 6, function()
        self:RefreshStats()
    end)

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("Inventory/UpdateTotalLootSpawns", self, self.UpdateTotalLootSpawns)
    Events:Subscribe("Drones/UpdateTotalDrones", self, self.UpdateTotalDrones)
    Events:Subscribe("build/TotalBuildObjectsUpdate", self, self.TotalBuildObjectsUpdate)
    Events:Subscribe("Vehicles/UpdateVehicleTotalStats", self, self.UpdateVehicleTotalStats)

end

function sServerStats:UpdateVehicleTotalStats(args)
    self.stats["Vehicles"] = args.total
    self:Refresh()
end

function sServerStats:TotalBuildObjectsUpdate(args)
    self.stats["BuildObjects"] = args.total
    self:Refresh()
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

function sServerStats:RefreshStats()
    
    local uniquePlayers = SQL:Query("SELECT COUNT(*) FROM player_data"):Execute()
    self.stats["UniquePlayers"] = uniquePlayers[1]["COUNT(*)"]
    local boxesLooted = SQL:Query("SELECT SUM(tier1_looted + tier2_looted + tier3_looted + tier4_looted) FROM player_data"):Execute()
    self.stats["BoxesLooted"] = boxesLooted[1]["SUM(tier1_looted + tier2_looted + tier3_looted + tier4_looted)"]
    local droneKills = SQL:Query("SELECT SUM(kills) FROM drone_kills"):Execute()
    self.stats["DronesDestroyed"] = droneKills[1]["SUM(kills)"]
    local playerKills = SQL:Query("SELECT SUM(kills) FROM player_data"):Execute()
    self.stats["TotalKills"] = playerKills[1]["SUM(kills)"]
    local playerDeaths = SQL:Query("SELECT SUM(deaths) FROM player_data"):Execute()
    self.stats["TotalDeaths"] = playerDeaths[1]["SUM(deaths)"]
    local stashes = SQL:Query("SELECT COUNT(*) FROM stashes WHERE type == 11 or type == 12 or type == 13"):Execute()
    self.stats["TotalStashes"] = stashes[1]["COUNT(*)"]
    local mineCount = SQL:Query("SELECT COUNT(*) FROM mines"):Execute()
    mineCount = mineCount[1]["COUNT(*)"]
    local claymoreCount = SQL:Query("SELECT COUNT(*) FROM claymores"):Execute()
    claymoreCount = claymoreCount[1]["COUNT(*)"]
    self.stats["PlacedExplosives"] = mineCount + claymoreCount
    
    self:Refresh()
end

sServerStats = sServerStats()