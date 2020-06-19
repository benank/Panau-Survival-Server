class 'cDroneBody'

local DEBUG_ON = true

function cDroneBody:__init(args)

    self.position = args.position
    self.angle = args.angle

    self:CreateBody()

    if DEBUG_ON then
        Events:Subscribe("GameRender", self, self.GameRender)
    end
end

function cDroneBody:PostTick(args)

    if IsValid(self.effect) then
        self.effect:SetPosition(self.position + self.angle * DroneEffectOffset.angle * DroneEffectOffset.position)
    end

end

function cDroneBody:GameRender(args)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.LeftGun)), 5, Color.Red)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.RightGun)), 5, Color.Yellow)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.TopGun)), 5, Color.Green)

    local left_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.LeftGun), self.angle * Angle(-0.01, 0, 0) * Vector3.Forward, 0, 100)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.LeftGun), left_ray.position, Color.Red)

    local right_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.RightGun), self.angle * Angle(0.01, 0, 0) * Vector3.Forward, 0, 100)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.RightGun), right_ray.position, Color.Red)
end

function cDroneBody:GetGunPosition(gun_enum)
    return self.position + self.angle * DroneGunOffsets[gun_enum].angle * DroneGunOffsets[gun_enum].position
end

function cDroneBody:CreateBody()

    self.objects = {}

    for piece_enum, object_data in pairs(DroneBodyObjects) do

        self.objects[piece_enum] = ClientStaticObject.Create({
            position = self.position + self.angle * DroneBodyOffsets[piece_enum].position,
            angle = self.angle * DroneBodyOffsets[piece_enum].angle,
            model = object_data.model,
            collision = object_data.collision,
            --fixed = false
        })

    end

    self.effect = ClientParticleSystem.Create(AssetLocation.Game, {
        position = self.position + DroneEffectOffset.angle * DroneEffectOffset.position,
        angle = DroneEffectOffset.angle,
        path = "fx_vehicle_jetthrust_medium_01.psmb"
    })

end

function cDroneBody:SetPosition(pos)
    self.position = pos
    self.effect:SetPosition(self.position)

    for piece_enum, object in pairs(self.objects) do
        object:SetPosition(self.position + self.angle * DroneBodyOffsets[piece_enum].angle * DroneBodyOffsets[piece_enum].position)
    end

end

function cDroneBody:SetAngle(ang)
    self.angle = ang

    for piece_enum, object in pairs(self.objects) do
        object:SetAngle(self.angle * DroneBodyOffsets[piece_enum].angle)
    end

    self:SetPosition(self.position)

end

function cDroneBody:Remove()
    -- Remove all Static objects
    for piece_enum, object in pairs(self.objects) do
        object:Remove()
    end

    self.effect:Remove()
end