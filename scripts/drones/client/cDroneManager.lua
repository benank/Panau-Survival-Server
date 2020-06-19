class 'cDroneManager'

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

        drone.target_position = LocalPlayer:GetPosition() + Vector3.Up * 5 + Vector3.Left * 15

        local angle = Angle.FromVectors(Vector3.Forward, local_pos - drone.position)
        angle.roll = 0
        drone:SetPosition(math.lerp(drone.position, drone.target_position, 2 * args.delta))
        drone:SetAngle(Angle.Slerp(drone.angle, angle, 0.5))
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
            position = LocalPlayer:GetPosition() + Vector3.Up * 2 + Vector3.Left,
            angle = LocalPlayer:GetAngle()
        }))

    end

end

cDroneManager = cDroneManager()