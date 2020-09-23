class 'cDroneManager'

local DEBUG_ON = false

function cDroneManager:__init()

    self.drones = {}

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PostTick", self, self.PostTick)

    Network:Subscribe("Drones/SingleSync", self, self.SingleDroneSync)
    Network:Subscribe("Drones/DroneCellsSync", self, self.CellsDroneSync)

    Events:Subscribe("HitDetection/Explosion", self, self.HitDetectionExplosion)
    Events:Subscribe("HitDetection/BulletSplash", self, self.HitDetectionBulletSplash)

    Events:Subscribe("Cells/LocalPlayerCellUpdate" .. tostring(Cell_Size), self, self.LocalPlayerCellUpdate)

    if DEBUG_ON then
        Events:Subscribe("Render", self, self.GameRender)
    end

    Thread(function()
        while true do
            local path_count = 0
            local host_count = 0
            local count = 0
            for id, drone in pairs(self.drones) do
                count = count + 1
                if count_table(drone.path) > 0 then
                    path_count = path_count + 1
                end
                if drone.host then
                    host_count = host_count + 1
                end
                Timer.Sleep(1)
            end
            print(string.format("%d/%d path counts", path_count, count))
            print(string.format("%d/%d host counts", host_count, count))
            Timer.Sleep(1000)
        end
    end)


    self:DroneHostLoop()

end

function cDroneManager:GameRender(args)
    for id, drone in pairs(self.drones) do
        drone:GameRender(args)
    end
end

function cDroneManager:HitDetectionBulletSplash(args)
    Thread(function()
        for id, drone in pairs(self.drones) do
            local distance = drone.position:Distance(args.hit_position)
            if distance < args.radius then
                args.drone_position = drone.position
                args.hit_position = drone.position
                args.drone_distance = distance
                args.drone_id = id
                Events:Fire("HitDetection/SplashHitDrone", args)
            end
            Timer.Sleep(1)
        end
    end)
end

function cDroneManager:HitDetectionExplosion(args)
    Thread(function()
        for id, drone in pairs(self.drones) do
            local distance = drone.position:Distance(args.position)
            if distance < 300 then -- Temp radius because HitDetection stores these
                args.drone_position = drone.position
                args.drone_distance = distance
                args.drone_id = id
                Events:Fire("HitDetection/ExplosionHitDrone", args)
            end
            Timer.Sleep(1)
        end
    end)
end

function cDroneManager:LocalPlayerCellUpdate(args)
    
    -- Remove drones from old cells
    Thread(function()
        for _, cell in pairs(args.old_adjacent) do
            for id, drone in pairs(self.drones) do
                local drone_cell = GetCell(drone.position, Cell_Size)
                if cell.x == drone_cell.x and cell.y == drone_cell.y then
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
                if IsValid(drone.host) and drone.host == LocalPlayer then
                    drone:PerformHostActions()
                    Timer.Sleep(100)
                end
            end
            Timer.Sleep(1500)
        end
    end)
end

function cDroneManager:CellsDroneSync(args)

    Thread(function()
        for _, drone_data in pairs(args.drone_data) do
            if not self.drones[drone_data.id] then
                self.drones[drone_data.id] = cDrone(drone_data)
            else
                self.drones[drone_data.id]:UpdateFromServer(drone_data)
            end
            Timer.Sleep(1)
        end
    end)

end

function cDroneManager:SingleDroneSync(args)
    if not self.drones[args.id] and args.level then
        self.drones[args.id] = cDrone(args)
    elseif self.drones[args.id] then
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