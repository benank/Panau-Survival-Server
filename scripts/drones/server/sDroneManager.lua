class 'sDroneManager'

function sDroneManager:__init()

    self.drones = {} -- Drones in cells [x][y][id] = drone
    self.drones_by_id = {} -- Drones by id
    self.drone_counts_by_region = {} -- Counts of drones per region for spawning
    self.player_cells = {} -- Players in cells [x][y][steam_id] = player

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Cell_Size), self, self.PlayerCellUpdate)

    if IsTest then
        Events:Subscribe("PlayerChat", self, self.PlayerChat)
    end

    Events:Subscribe("HitDetection/DroneDamaged", self, self.DroneDamaged)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)

end

function sDroneManager:ModuleLoad()
    self:DroneSpawnLoop()
    self:SpawnInitialDrones()
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

        for i = 1, math.floor(region.spawn.max / 2) do
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

    return region.center + Vector3(dir.x * region.radius, 30, dir.z * region.radius)
end

function sDroneManager:DroneDamaged(args)
    local drone = self.drones_by_id[args.drone_id]
    if not drone then return end

    drone:Damage(args)
end

function sDroneManager:PlayerChat(args)

    --if not IsAdmin(args.player) then return end

    if args.text == "/drone" then
        sDrone({
            region = DroneRegionEnum.FinancialDistrict,
            position = args.player:GetPosition() + Vector3.Up * 2
        })
        _debug("Drone created")
    end

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
        self.player_cells[args.old_cell.x][args.old_cell.y][tostring(args.player:GetSteamId().id)] = nil
    end

    VerifyCellExists(self.player_cells, cell)
    self.player_cells[cell.x][cell.y][tostring(args.player:GetSteamId().id)] = args.player

end

function sDroneManager:GetNearbyPlayersInCell(cell)

    local nearby_players = {}

    -- Sync to all players in adjacent cells
    for x = cell.x - 1, cell.x + 1 do

        for y = cell.y - 1, cell.y + 1 do

            VerifyCellExists(self.player_cells, {x = x, y = y})
            for _, player in pairs(self.player_cells[x][y]) do

                if IsValid(player) then
                    table.insert(nearby_players, player)
                end

            end

        end

    end

    return nearby_players

end

function sDroneManager:PlayerCellUpdate(args)

    self:UpdatePlayerInCell(args)
    
    local drone_data = {}

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