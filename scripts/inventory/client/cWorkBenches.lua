class 'cWorkBenches'

function cWorkBenches:__init()

    self.idle_sounds = {}
    self.fx = {}

    self.signal_color = Color(255, 200, 0, 50)

    self.active_workbenches = {} -- [id] = {position}

    Network:Subscribe("Workbenches/SyncStatus", self, self.SyncStatus)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cWorkBenches:SyncStatus(args)

    if not self.idle_sounds[args.name] then
        self.idle_sounds[args.name] = self:CreateAmbientWorkbenchSound(args.position)
    end

    if args.state == WorkBenchState.Idle then

        if self.fx[args.name] then

            for _, fx in pairs(self.fx[args.name]) do
                if IsValid(fx) then fx:Remove() end
            end

            self.fx[args.name] = nil
        end

        self.active_workbenches[args.name] = nil

        if args.finished then
            self:PlayFinishEffect(args.position)
        end

    elseif args.state == WorkBenchState.Combining then

        self.fx[args.name] = 
        {
            self:PlayCombiningSound(args.position), 
            self:CreateCombiningEffect(args.position),
            self:CreateCombiningLight(args.position)
        }

        self.active_workbenches[args.name] = {position = args.position, time_left = args.time_left, timer = Timer()}

    end

    -- Draw big streaks in the sky if the workbench is active
    if count_table(self.active_workbenches) > 0 and not self.render then
        self.render = Events:Subscribe("GameRender", self, self.GameRender)
    elseif count_table(self.active_workbenches) == 0 and self.render then
        self.render = Events:Unsubscribe(self.render)
    end

    -- Fire event to update map
    Events:Fire("Workbenches/UpdateState", {
        name = args.name,
        state = args.state -- 1 for idle, 2 for combining
    })
end

function cWorkBenches:GameRender(args)

    local angle = Angle(Camera:GetAngle().yaw,0,0)

    for index, data in pairs(self.active_workbenches) do

        local t = Transform3():Translate(data.position + Vector3.Up):Rotate(angle * Angle(0, math.pi, 0))
        Render:SetTransform(t)

        local color = Color.Red
        local text = string.format("%.0f", math.max(0, data.time_left - data.timer:GetSeconds()))

        local text_size = Render:GetTextWidth(text, 200, 0.003)
        Render:DrawText(Vector3(-text_size * 0.1, -0.5, 0), text, color, 200, 0.003)
        
        Render:ResetTransform()

        -- Draw two large lines
		local t = Transform3():Translate(data.position + Vector3(6, -1000, 0)):Rotate(angle)
		Render:SetTransform(t)
		
        Render:FillArea(Vector3(-0.7, 0, 0), Vector3(1.5, 4000, 0), self.signal_color)

        Render:ResetTransform()


		local t = Transform3():Translate(data.position + Vector3(-6, -1000, 0)):Rotate(angle)
		Render:SetTransform(t)
		
        Render:FillArea(Vector3(-0.7, 0, 0), Vector3(1.5, 4000, 0), self.signal_color)

        Render:ResetTransform()

        

    end

end

function cWorkBenches:PlayFinishEffect(pos)

    ClientEffect.Play(AssetLocation.Game, {
        position = pos,
        angle = Angle(),
        effect_id = 79
    })

end

function cWorkBenches:CreateCombiningLight(pos)

    return ClientLight.Create({
        position = pos + Vector3(0, 1, 0),
        color = self.signal_color,
        multiplier = 5,
        radius = 50
    })

end

function cWorkBenches:CreateAmbientWorkbenchSound(pos)
    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 32,
        sound_id = 24,
        position = pos,
        angle = Angle()
    })

    sound:SetParameter(0,1)
    sound:SetParameter(1,0)
    sound:SetParameter(2,0)

    return sound

end

function cWorkBenches:PlayCombiningSound(pos)

    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 40,
        position = pos,
        angle = Angle()
    })

    sound:SetParameter(0,1)

    return sound

end

function cWorkBenches:CreateCombiningEffect(pos)
    return ClientEffect.Create(AssetLocation.Game, {
        position = pos,
        angle = Angle(),
        effect_id = 118
    })
end

function cWorkBenches:ModuleUnload()
    for _, sound in pairs(self.idle_sounds) do
        if IsValid(sound) then sound:Remove() end
    end

    for name, fx in pairs(self.fx) do
        for _, effect in pairs(fx) do
            if IsValid(effect) then effect:Remove() end
        end
    end

end

cWorkBenches = cWorkBenches()