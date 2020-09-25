class 'cDroneBody'

function cDroneBody:__init(parent)

    self.parent = parent

    self.sounds = {}

    self:CreateBody()
    self:HealthUpdated()
end

function cDroneBody:HealthUpdated()

    for enum, object in pairs(self.objects) do
        Events:Fire("drones/UpdateDroneCSO", {id = self.parent.id, cso_id = object:GetId(), health = self.parent.health, max_health = self.parent.max_health, level = self.parent.level})
    end

    -- No logic for healing because drones will never heal
    if self.parent.health <= self.parent.max_health * 0.20 and not IsValid(self.smoke_fx) and not self.parent:IsDestroyed() then
        self.smoke_fx = ClientEffect.Create(AssetLocation.Game, {
            position = self.parent.position,
            angle = Angle(),
            effect_id = 167 -- 166 for not as huge FX
        })
    end
end

function cDroneBody:ContainsStaticObject(cso)
    for _, object in pairs(self.objects) do
        if object == cso then return true end
    end
end

function cDroneBody:PostTick(args)

    if IsValid(self.effect) then
        self.effect:SetPosition(self.parent.position + self.parent.angle * DroneEffectOffset.angle * DroneEffectOffset.position)
    end

    if IsValid(self.light) then
        self.light:SetPosition(self:GetGunPosition(DroneBodyPiece.TopGun) + self.parent.angle * Vector3.Forward * 0.5)
    end

    if IsValid(self.smoke_fx) then
        self.smoke_fx:SetPosition(self.parent.position)
    end

    if self.red_blip_timer and self.red_blip_timer:GetSeconds() >= 1 and not self.red_blip_effect then
        self.red_blip_timer:Restart()
        self.red_blip_effect = ClientEffect.Create(AssetLocation.Game, {
            position = self.parent.position + self.parent.angle * DroneRedBlipOffset.position,
            angle = self.parent.angle,
            effect_id = 280
        })
        Timer.SetTimeout(700, function()
            if IsValid(self.red_blip_effect) then
                self.red_blip_effect = self.red_blip_effect:Remove()
            end
        end)
    elseif IsValid(self.red_blip_effect) then
        self.red_blip_effect:SetPosition(self.parent.position + self.parent.angle * DroneRedBlipOffset.position)
    end

    for name, sound in pairs(self.sounds) do
        sound:SetPosition(self.parent.position)
    end

end

function cDroneBody:GameRender(args)
    Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.LeftGun)), 10, Color.Red)
    if true then return end
    Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.RightGun)), 10, Color.Yellow)
    Render:FillCircle(Render:WorldToScreen(self:GetGunPosition(DroneBodyPiece.TopGun)), 10, Color.Green)

    local range = self.parent.config.sight_range

    local left_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.LeftGun), self:GetGunAngle(DroneBodyPiece.LeftGun) * Vector3.Forward, 0, range, false)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.LeftGun), left_ray.position, Color.Red)

    local right_ray = Physics:Raycast(self:GetGunPosition(DroneBodyPiece.RightGun), self:GetGunAngle(DroneBodyPiece.RightGun) * Vector3.Forward, 0, range, false)
    Render:DrawLine(self:GetGunPosition(DroneBodyPiece.RightGun), right_ray.position, Color.Red)
end

function cDroneBody:GetGunAngle(gun_enum)
    return self.parent.angle * (gun_enum == DroneBodyPiece.LeftGun and Angle(-0.005, 0, 0) or Angle(0.005, 0, 0))
end

function cDroneBody:GetGunPosition(gun_enum)
    return self.parent.position + self.parent.angle * DroneGunOffsets[gun_enum].angle * DroneGunOffsets[gun_enum].position
end

function cDroneBody:PlaySound(sound_name)
    if self.sounds[sound_name] then return end

    local sound
    if sound_name == "hostile_spotted" then
        sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 40,
            sound_id = 69,
            position = self.parent.position,
            angle = self.parent.angle
        })
        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
    elseif sound_name == "be_on_the_lookout" then
        sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 40,
            sound_id = 86,
            position = self.parent.position,
            angle = self.parent.angle
        })
        
        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
    elseif sound_name == "intruder_alert" then
        sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 40,
            sound_id = 81,
            position = self.parent.position,
            angle = self.parent.angle
        })
        
        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
    elseif sound_name == "enemy_presence_in_the_area" then
        sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 40,
            sound_id = 80,
            position = self.parent.position,
            angle = self.parent.angle
        })
        
        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
    elseif sound_name == "trespasser_in_the_area" then
        sound = ClientSound.Create(AssetLocation.Game, {
			bank_id = 40,
			sound_id = 72,
            position = self.parent.position,
            angle = self.parent.angle
        })

        sound:SetParameter(0,1)
        sound:SetParameter(1,0)
    end

    self.sounds[sound_name] = sound

    Timer.SetTimeout(10000, function()
        if IsValid(self.sounds[sound_name]) then
            self.sounds[sound_name] = self.sounds[sound_name]:Remove()
        end
    end)


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

    -- TODO: add bullet hit effect on surface if it hits something

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

    local body_objects = Copy(DroneBodyObjects)
    if not self.parent.config.has_rockets then
        body_objects[DroneBodyPiece.TopGun] = nil
    end

    for piece_enum, object_data in pairs(body_objects) do

        self.objects[piece_enum] = ClientStaticObject.Create({
            position = self.parent.position + self.parent.angle * DroneBodyOffsets[piece_enum].position,
            angle = self.parent.angle * DroneBodyOffsets[piece_enum].angle,
            model = object_data.model,
            collision = object_data.collision
        })
        Events:Fire("drones/CreateDroneCSO", {id = self.parent.id, cso_id = self.objects[piece_enum]:GetId(), health = self.parent.health, max_health = self.parent.max_health, level = self.parent.level})

    end

    self.effect = ClientParticleSystem.Create(AssetLocation.Game, {
        position = self.parent.position + DroneEffectOffset.angle * DroneEffectOffset.position,
        angle = DroneEffectOffset.angle,
        path = "fx_ballonengine_01.psmb"
    })

    if self.parent.config.attack_on_sight then
        self.red_blip_timer = Timer()
    end

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

    self.effect:SetAngle(self.parent.angle * DroneEffectOffset.angle)

    self:SetPosition(self.parent.position)

end

function cDroneBody:Remove()
    -- Remove all Static objects
    for piece_enum, object in pairs(self.objects) do
        Events:Fire("drones/RemoveDroneCSO", {id = self.parent.id, cso_id = object:GetId()})
        object:Remove()
    end

    for _, sound in pairs(self.sounds) do
        sound:Remove()
    end

    self.effect:Remove()

    if IsValid(self.light) then
        self.light:Remove()
    end

    if IsValid(self.smoke_fx) then
        self.smoke_fx:Remove()
    end

    if IsValid(self.red_blip_effect) then
        self.red_blip_effect:Remove()
    end

    if self.debug_render then
        Events:Unsubscribe(self.debug_render)
    end
end