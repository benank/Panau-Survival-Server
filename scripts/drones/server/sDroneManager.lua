class 'sDroneManager'

function sDroneManager:__init()

    self.drones = {} -- Drones in cells [x][y][id] = drone
    self.drones_by_id = {} -- Drones by id
    self.drone_counts_by_region = {} -- Counts of drones per region for spawning
    self.player_cells = {} -- Players in cells [x][y][steam_id] = player

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Cell_Size), self, self.PlayerCellUpdate)
    Events:Subscribe("HitDetection/DroneDamaged", self, self.DroneDamaged)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)

    Network:Subscribe("drones/sync/batch", self, self.DroneBatchSync)

end

function sDroneManager:ModuleLoad()
    self:DroneSpawnLoop()
    self:SpawnInitialDrones()
    self:DroneReconsiderLoops()
    self:DroneBatchSyncLoop()
end

function sDroneManager:DroneBatchSync(args, player)
    for drone_id, data in pairs(args) do
        if self.drones_by_id[drone_id] then
            self.drones_by_id[drone_id]:OneHostSync(data, player)
        end
    end
end

-- Sync drone updates using a batched method for cells. One sync per cell to nearby players
function sDroneManager:DroneBatchSyncLoop()
    Thread(function()
        while true do

            local drone_data = {}
            local at_least_one_sync = false
            for id, drone in pairs(self.drones_by_id) do
                if drone.has_update then
                    drone_data[id] = drone.updates
                    if drone.updates.health then
                        print("UPDATING HEALTH " .. tostring(drone.health))
                    end
                    at_least_one_sync = true
                    drone:UpdateApplied()
                end
            end

            if at_least_one_sync then
                Network:Broadcast("Drones/BatchSync", drone_data)
            end

            Timer.Sleep(250)
        end
    end)
end

function sDroneManager:DroneReconsiderLoops()
    Thread(function()
        while true do
            for id, drone in pairs(self.drones_by_id) do
                drone:ReconsiderLoop()
                Timer.Sleep(1)
            end
            Timer.Sleep(250)
        end
    end)
end

function sDroneManager:DroneSpawnLoop()
    -- Spawn drone 
    Timer.SetInterval(DRONE_SPAWN_INTERVAL * 1000 * 60, function()
        for region_enum, region in pairs(DroneRegions) do
            if self.drone_counts_by_region[region_enum] < region.spawn.max and math.random() <= region.spawn.chance then
                sDrone({
                    region = region_enum,
                    position = self:GetRandomPositionInRegion(region_enum)
                })
            end
        end
    end)
end

-- Initially spanw half of max drones in each area on reload
function sDroneManager:SpawnInitialDrones()
    local count = 0
    for region_enum, region in pairs(DroneRegions) do
        self.drone_counts_by_region[region_enum] = 0

        for i = 1, region.spawn.max do
            sDrone({
                region = region_enum,
                position = self:GetRandomPositionInRegion(region_enum)
            })
            count = count + 1
        end
    end
    print(string.format("Spawned %d drones.", count))
end

function sDroneManager:GetRandomPositionInRegion(region_enum)
    local region = DroneRegions[region_enum]
    assert(region, "Region should exist")

    -- Get normalized vector direction
    local dir = Vector3(0.5 - math.random(), 0, 0.5 - math.random()):Normalized()
    -- Scale the direction so it's not always on the outer edge
    dir = dir * math.random()

    return region.center + Vector3(dir.x * region.radius, 30 + GetExtraHeightOfDroneFromRegion(region_enum), dir.z * region.radius)
end

function sDroneManager:DroneDamaged(args)
    local drone = self.drones_by_id[args.drone_id]
    if not drone then return end

    drone:Damage(args)
end

function sDroneManager:ModuleUnload()
    for id, drone in pairs(self.drones_by_id) do
        drone:Remove()
    end
end

-- Updates player_cells
function sDroneManager:UpdatePlayerInCell(args)
    local cell = args.cell

    if args.old_cell.x ~= nil and args.old_cell.y ~= nil then
        VerifyCellExists(self.player_cells, args.old_cell)
        self.player_cells[args.old_cell.x][args.old_cell.y][tostring(args.player:GetSteamId())] = nil
    end

    VerifyCellExists(self.player_cells, cell)
    self.player_cells[cell.x][cell.y][tostring(args.player:GetSteamId())] = args.player

end

function sDroneManager:GetNearbyPlayersInCell(cell)

    local nearby_players = {}
    local adjacent_cells = GetAdjacentCells(cell)

    -- Sync to all players in adjacent cells
    for _, adj_cell in pairs(adjacent_cells) do
        VerifyCellExists(self.player_cells, adj_cell)
        for _, player in pairs(self.player_cells[adj_cell.x][adj_cell.y]) do
            if IsValid(player) then
                table.insert(nearby_players, player)
            end
        end
    end

    return nearby_players

end

function sDroneManager:PlayerCellUpdate(args)

    self:UpdatePlayerInCell(args)
    
    local drone_data = {}

    local adjacent_cells = GetAdjacentCells(args.cell)

    for _, adj_cell in pairs(adjacent_cells) do
        -- If these cells don't exist, create them
        VerifyCellExists(self.drones, adj_cell)

        for id, drone in pairs(self.drones[adj_cell.x][adj_cell.y]) do
            if not IsValid(drone.host) then
                drone:SetHost(args.player)
            end
        end
    end

    for _, update_cell in pairs(args.updated) do

        -- If these cells don't exist, create them
        VerifyCellExists(self.drones, update_cell)

        for id, drone in pairs(self.drones[update_cell.x][update_cell.y]) do
            table.insert(drone_data, drone:GetSyncData())
        end
    end
    
	-- send the existing drones in the newly streamed cells
    Network:Send(args.player, "Drones/DroneCellsSync", {drone_data = drone_data})
end

sDroneManager = sDroneManager()