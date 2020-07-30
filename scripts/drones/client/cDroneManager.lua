class 'cDroneManager'

DRONE_SPEED = 10

function cDroneManager:__init()

    self.drones = {}

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PostTick", self, self.PostTick)

    Network:Subscribe("Drones/SingleSync", self, self.SingleDroneSync)
    Network:Subscribe("Drones/DroneCellsSync", self, self.CellsDroneSync)

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

function cDroneManager:LocalPlayerChat(args)

    if args.text == "/drones" then

        for i = 1, 50 do

            table.insert(self.drones, cDrone({
                position = LocalPlayer:GetPosition() + Vector3.Up * 2 + Vector3(0.5 - math.random(), 0, 0.5 - math.random()):Normalized() * 600,
                angle = LocalPlayer:GetAngle()
            }))

        end

    end

end

cDroneManager = cDroneManager()