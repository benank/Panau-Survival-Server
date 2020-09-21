class 'cDroneManager'

function cDroneManager:__init()

    self.drones = {}

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PostTick", self, self.PostTick)

    Network:Subscribe("Drones/SingleSync", self, self.SingleDroneSync)
    Network:Subscribe("Drones/DroneCellsSync", self, self.CellsDroneSync)

    Events:Subscribe("Cells/LocalPlayerCellUpdate" .. tostring(Cell_Size), self, self.LocalPlayerCellUpdate)

    self:DroneHostLoop()

end

function cDroneManager:LocalPlayerCellUpdate(args)
    
    -- Remove drones from old cells
    Thread(function()
        for _, cell in pairs(args.old_adjacent) do
            for id, drone in pairs(self.drones) do
                local drone_cell = GetCell(drone.position, Cell_Size)
                if cell.x == drone_cell.x and cell.y == drone_cell.y then
                    _debug("stream out drone")
                    drone:Remove()
                    self.drones[id] = nil
                end
            end
        end
    end)

end

function cDroneManager:DroneHostLoop()
    Thread(function()
        while true do
            for id, drone in pairs(self.drones) do
                if drone.host == LocalPlayer then
                    drone:PerformHostActions()
                    Timer.Sleep(100)
                end
            end
            Timer.Sleep(1500)
        end
    end)
end

function cDroneManager:CellsDroneSync(args)

    for _, drone_data in pairs(args.drone_data) do
        if not self.drones[drone_data.id] then
            self.drones[drone_data.id] = cDrone(args)
        else
            self.drones[drone_data.id]:UpdateFromServer(args)
        end
    end

end

function cDroneManager:SingleDroneSync(args)

    if not self.drones[args.id] then
        self.drones[args.id] = cDrone(args)
    else
        self.drones[args.id]:UpdateFromServer(args)
    end

end

function cDroneManager:PostTick(args)

    local local_pos = LocalPlayer:GetBonePosition("ragdoll_Hips")

    for _, drone in pairs(self.drones) do
        drone:PostTick(args)
    end

end

function cDroneManager:ModuleUnload()
    for _, drone in pairs(self.drones) do
        drone:Remove()
    end
end

cDroneManager = cDroneManager()