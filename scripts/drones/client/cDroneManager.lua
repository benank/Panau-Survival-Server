class 'cDroneManager'

DRONE_SPEED = 10

function cDroneManager:__init()

    self.drones = {}

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PostTick", self, self.PostTick)

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

    if args.text == "/drone" then

        table.insert(self.drones, cDrone({
            position = LocalPlayer:GetPosition() + Vector3.Up * 2 + Vector3(0.5 - math.random(), 0, 0.5 - math.random()):Normalized() * 10,
            angle = LocalPlayer:GetAngle()
        }))

    elseif args.text == "/drones" then

        for i = 1, 50 do

            table.insert(self.drones, cDrone({
                position = LocalPlayer:GetPosition() + Vector3.Up * 2 + Vector3(0.5 - math.random(), 0, 0.5 - math.random()):Normalized() * 600,
                angle = LocalPlayer:GetAngle()
            }))

        end

    end

end

cDroneManager = cDroneManager()