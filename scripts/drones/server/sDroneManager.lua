class 'sDroneManager'

function sDroneManager:__init()

    self.drones = {} -- Drones in cells [x][y][id] = drone
    self.player_cells = {} -- Players in cells [x][y][steam_id] = player

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Cell_Size), self, self.PlayerCellUpdate)

    if IsTest then
        Events:Subscribe("PlayerChat", self, self.PlayerChat)
    end

    Events:Subscribe("HitDetection/DroneDamaged", self, self.DroneDamaged)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function sDroneManager:DroneDamaged(args)
    local cell = GetCell(args.hit_position, Cell_Size)
    if not self.drones[cell.x] or not self.drones[cell.x][cell.y] then return end

    local drone = self.drones[cell.x][cell.y][args.drone_id]
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
    for cell_x, _ in pairs(self.drones) do
        for cell_y, _ in pairs(self.drones[cell_x]) do
            for id, drone in pairs(self.drones[cell_x][cell_y]) do
                drone:Remove()
            end
        end
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

    for _, old_cell in pairs(args.old_adjacent) do

        -- If these cells don't exist, create them
        VerifyCellExists(self.drones, old_cell)

        -- Remove player as drone host from old cells
        for id, drone in pairs(self.drones[old_cell.x][old_cell.y]) do
            if drone.host == args.player then
                drone.host = nil
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