class 'cDroneBody'

local DEBUG_ON = false

function cDroneBody:__init(parent)

    self.parent = parent

    self.sounds = {}

    self:CreateBody()

    if DEBUG_ON then
        Events:Subscribe("GameRender", self, self.GameRender)
    end
end

function cDroneBody:PostTick(args)

    if IsValid(self.effect) then
        self.effect:SetPosition(self.parent.position + self.parent.angle * DroneEffectOffset.angle * DroneEffectOffset.position)
    end

    if IsValid(self.light) then
        self.light:SetPosition(self:GetGunPosition(DroneBodyPiece.TopGun) + self.parent.angle * Vector3.Forward * 0.5)
    end

end

function cDroneBody:GameRender(args)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.LeftGun)), 5, Color.Red)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.RightGun)), 5, Color.Yellow)
    --Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.TopGun)), 5, Color.Green)

    local left_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.LeftGun), self.parent.angle * Angle(-0.005, 0, 0) * Vector3.Forward, 0, 100, false)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.LeftGun), left_ray.position, Color.Red)

    local right_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.RightGun), self.parent.angle * Angle(0.005, 0, 0) * Vector3.Forward, 0, 100, false)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.RightGun), right_ray.position, Color.Red)
end

function cDroneBody:GetGunPosition(gun_enum)
    return self.parent.position + self.parent.angle * DroneGunOffsets[gun_enum].angle * DroneGunOffsets[gun_enum].position
end

function cDroneBody:CreateShootingEffect(gun_enum)
    local pos = self:GetGunPosition(gun_enum) + self.parent.angle * DroneMuzzleFlashOffset.angle * DroneMuzzleFlashOffset.position
    ClientEffect.Play(AssetLocation.Game, {
        position = pos,
        angle = self.parent.angle * DroneMuzzleFlashOffset.angle,
        effect_id = 50
    })

    local volume = 1 - math.min(1, Camera:GetPosition():Distance(self.parent.position) / 100)

    if not self.light then
        self.light = ClientLight.Create({
            position = pos,
            color = Color(252, 193, 15),
            radius = 1.5,
            multiplier = 8
        })
    end

    if not self.sounds["fire"] then
        self.sounds["fire"] = ClientSound.Create(AssetLocation.Game, {
            bank_id = 0,
            sound_id = 13,
            position = self.parent.position,
            angle = self.parent.angle
        })

        self.sounds["fire"]:SetParameter(0,0)
        self.sounds["fire"]:SetParameter(1,0)
        self.sounds["fire"]:SetParameter(2,volume)

    elseif self.fire_sound_timeout then
        Timer.Clear(self.fire_sound_timeout)
        self.sounds["fire"]:SetPosition(self.parent.position)
        self.sounds["fire"]:SetAngle(self.parent.angle)
        self.sounds["fire"]:SetParameter(2,volume)
    end

    self.fire_sound_timeout = Timer.SetTimeout(150, function()
        if IsValid(self.sounds["fire"]) then
            self.sounds["fire"] = self.sounds["fire"]:Remove()
        end
        self.fire_sound_timeout = nil

        if IsValid(self.light) then
            self.light = self.light:Remove()
        end
    end)

end

function cDroneBody:CreateBody()

    self.objects = {}

    for piece_enum, object_data in pairs(DroneBodyObjects) do

        self.objects[piece_enum] = ClientStaticObject.Create({
            position = self.parent.position + self.parent.angle * DroneBodyOffsets[piece_enum].position,
            angle = self.parent.angle * DroneBodyOffsets[piece_enum].angle,
            model = object_data.model,
            collision = object_data.collision,
            --fixed = false
        })

    end

    self.effect = ClientParticleSystem.Create(AssetLocation.Game, {
        position = self.parent.position + DroneEffectOffset.angle * DroneEffectOffset.position,
        angle = DroneEffectOffset.angle,
        path = "fx_ballonengine_01.psmb"
    })

end

function cDroneBody:SetPosition()
    self.effect:SetPosition(self.parent.position)

    for piece_enum, object in pairs(self.objects) do
        object:SetPosition(self.parent.position + self.parent.angle * DroneBodyOffsets[piece_enum].angle * DroneBodyOffsets[piece_enum].position)
    end

end

function cDroneBody:SetAngle()

    for piece_enum, object in pairs(self.objects) do
        object:SetAngle(self.parent.angle * DroneBodyOffsets[piece_enum].angle)
    end

    self:SetPosition(self.parent.position)

end

function cDroneBody:Remove()
    -- Remove all Static objects
    for piece_enum, object in pairs(self.objects) do
        object:Remove()
    end

    for _, sound in pairs(self.sounds) do
        sound:Remove()
    end

    self.effect:Remove()

    if IsValid(self.light) then
        self.light:Remove()
    end
end