class 'cEvac'

function cEvac:__init()

    self.vertical_speed = 150
    self.horizontal_speed = 500
    self.objects = {}
    self.fx = {}

    self.dir = Vector3.Forward
    self.angle = Angle(0, 0, 0)

    Network:Subscribe(var("items/ActivateEvac"):get(), self, self.ActivateEvac)
    Events:Subscribe("Render", self, self.Render)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cEvac:ModuleUnload()
    for k,v in pairs(self.objects) do
        if IsValid(v) then v:Remove() end
    end
    for k,v in pairs(self.fx) do
        if IsValid(v) then v:Remove() end
    end
end

function cEvac:Render(args)

    for id, obj in pairs(self.objects) do
        if IsValid(obj) then

            local pos = obj:GetPosition()
            local starting_pos = obj:GetValue("StartingPos")
            local target_pos = obj:GetValue("TargetPos")
            local completion = obj:GetValue("Completion")
            local speed = obj:GetValue("Speed")
            local target_dist = obj:GetValue("Distance")

            if not obj:GetValue("UpdatingStage") then
                if completion < 1 then
                    obj:SetPosition(math.lerp(starting_pos, target_pos, completion))
                    obj:SetValue("Completion", math.min(1, completion + args.delta * speed / target_dist))

                    if obj:GetValue("Stage") == 4 then
                        local ray = Physics:Raycast(pos - Vector3(0, 8, 0), Vector3.Down, 0, 10)
                        local entity_is_player = ray.entity and (ray.entity.__type == "Player" or ray.entity.__type == "LocalPlayer")
                        local entity_is_ball = ray.entity and ray.entity.__type == "ClientStaticObject" and ray.entity == obj

                        if ray.distance < 10 and not entity_is_player and not entity_is_ball then
                            obj:SetValue("Completion", 1)
                        end
                    end

                    self.fx[id]:SetPosition(obj:GetPosition())
                else
                    self:UpdateStage(obj)
                end
            end

        end
    end

end

function cEvac:UpdateStage(ball)
    -- Called when a ball reaches a checkpoint position so we can update stage and target pos

    ball:SetValue("UpdatingStage", true)

    local stage = ball:GetValue("Stage")
    ball:SetValue("StartingPos", ball:GetPosition())

    -- Hide Fx
    self.fx[ball:GetId()]:SetPosition(Vector3(0,0,0))

    if stage == 1 then
        -- Reached the player initially
        self:PlayCountdownSound(ball:GetPosition())
    
        Timer.SetTimeout(10 * 1000, function()
            ball:SetValue("Speed", self.vertical_speed)
            ball:SetValue("Completion", 0)
            ball:SetValue("TargetPos", ball:GetPosition() + Vector3(0, 3000, 0))
            ball:SetValue("Distance", ball:GetPosition():Distance(ball:GetValue("TargetPos")))
            ball:SetValue("UpdatingStage", false)
            self.fx[ball:GetId()]:SetAngle(Angle.FromVectors((ball:GetPosition() - ball:GetValue("TargetPos")):Normalized(), self.dir) * self.angle)
        end)

    elseif stage == 2 then
        -- Reached the sky with the player on it

        Timer.SetTimeout(3 * 1000, function()
            local end_pos = ball:GetValue("EndPos")
            ball:SetValue("Speed", self.horizontal_speed)
            ball:SetValue("Completion", 0)
            ball:SetValue("TargetPos", Vector3(end_pos.x, ball:GetPosition().y, end_pos.z))
            ball:SetValue("Distance", ball:GetPosition():Distance(ball:GetValue("TargetPos")))
            ball:SetValue("UpdatingStage", false)
            self.fx[ball:GetId()]:SetAngle(Angle.FromVectors((ball:GetPosition() - ball:GetValue("TargetPos")):Normalized(), self.dir) * self.angle)
        end)

    elseif stage == 3 then
        -- Reached the sky above the waypoint
        
        Timer.SetTimeout(3 * 1000, function()
            local end_pos = ball:GetValue("EndPos")
            ball:SetValue("TargetPos", end_pos)
            ball:SetValue("Speed", self.vertical_speed)
            ball:SetValue("Completion", 0)
            ball:SetValue("Distance", ball:GetPosition():Distance(ball:GetValue("TargetPos")))
            ball:SetValue("UpdatingStage", false)
            self.fx[ball:GetId()]:SetAngle(Angle.FromVectors((ball:GetPosition() - ball:GetValue("TargetPos")):Normalized(), self.dir) * self.angle)
        end)

    elseif stage == 4 then
        -- Reached the waypoint

        local sound
        local destruct_sound

        if ball:GetPosition():Distance(Camera:GetPosition()) < 2000 then

            destruct_sound = ClientSound.Create(AssetLocation.Game, {
                bank_id = 40,
                sound_id = 53,
                position = ball:GetPosition(),
                angle = Angle()
            })

            destruct_sound:SetParameter(0,1)
            destruct_sound:SetParameter(1,0)

            Timer.SetTimeout(2000, function()
                sound = ClientSound.Create(AssetLocation.Game, {
                    bank_id = 23,
                    sound_id = 0,
                    position = ball:GetPosition(),
                    angle = Angle()
                })

                sound:SetParameter(0,0)
                sound:SetParameter(1,1)
                sound:SetParameter(2,0)
            end)
        end
        
        Timer.SetTimeout(10 * 1000, function()

            ClientEffect.Play(AssetLocation.Game, {
                effect_id = 83,
                position = ball:GetPosition(),
                angle = Angle()
            })

            if IsValid(sound) then sound:Remove() end
            if IsValid(destruct_sound) then destruct_sound:Remove() end
            self.objects[ball:GetId()] = nil
            ball:Remove()
        end)

    end

    ball:SetValue("Stage", stage + 1)

end

function cEvac:ActivateEvac(args)

    local ball = ClientStaticObject.Create({
        position = args.start_position + Vector3(0, 500, 0),
        angle = Angle(),
        model = "km07.submarine.eez/key014_02-v.lod",
        collision = "km07.submarine.eez/key014_02_lod1-v_col.pfx"
    })

    ball:SetValue("StartingPos", ball:GetPosition())
    ball:SetValue("UpdatingStage", false)
    ball:SetValue("Speed", self.vertical_speed / 2)
    ball:SetValue("Completion", 0)
    ball:SetValue("Stage", 1)
    ball:SetValue("EndPos", args.end_position)
    ball:SetValue("TargetPos", args.start_position)
    ball:SetValue("Distance", ball:GetPosition():Distance(ball:GetValue("TargetPos")))

    self.fx[ball:GetId()] = ClientEffect.Create(AssetLocation.Game, {
        position = ball:GetPosition(),
        angle = Angle.FromVectors((ball:GetPosition() - ball:GetValue("TargetPos")):Normalized(), self.dir) * self.angle,
        effect_id = 172
    })

    self.objects[ball:GetId()] = ball

    Events:Fire("Flare", {
        position = args.end_position,
        time = 60 * 2.5
    })

end

function cEvac:PlayCountdownSound(pos)

    if pos:Distance(Camera:GetPosition()) > 2000 then return end
    
    local seconds = 0
    local sound
    Thread(function()
        while seconds < 10 do

            local sound = ClientSound.Create(AssetLocation.Game, {
                bank_id = 40,
                sound_id = 59 + seconds,
                position = pos,
                angle = Angle()
            })
            
            sound:SetParameter(0,1)
            sound:SetParameter(1,0)
            
            seconds = seconds + 1
            Timer.Sleep(1000)
            sound:Remove()
        end
    end)

end

cEvac = cEvac()