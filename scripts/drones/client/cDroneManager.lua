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

        drone.target_position = LocalPlayer:GetPosition() + Vector3.Up * 4 + Vector3.Left * 10

        local angle = Angle.FromVectors(Vector3.Forward, local_pos - drone.position)
        angle.roll = 0

        local dir = drone.target_position - drone.position
        local velo = dir:Length() > 1 and ((dir):Normalized() * DRONE_SPEED) or Vector3.Zero

        drone:SetLinearVelocity(math.lerp(drone.velocity, velo, 0.01))

        drone:SetAngle(Angle.Slerp(drone.angle, angle, 0.05))

        if math.random() < 0.05 then
            drone.body:CreateShootingEffect(math.random() > 0.5 and DroneBodyPiece.LeftGun or DroneBodyPiece.RightGun)
        end
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