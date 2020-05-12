class 'cCloudStriderBoots'

function cCloudStriderBoots:__init()

    self.flight_enable_timer = Timer()
    self.flight_enable_window = 0.3
    self.trying_to_fly = false
    self.flying = false

    self.speed = 20
    self.shift_mod = 2

    self.sync_timer = Timer()
    self.sync_interval = 5

    self.movement = 
    {
        [Action.MoveForward] = Vector3.Forward,
        [Action.MoveBackward] = Vector3.Backward,
        [Action.MoveLeft] = Vector3.Left,
        [Action.MoveRight] = Vector3.Right,
        [Action.Jump] = Vector3.Up,
        [Action.Crouch] = Vector3.Down
    }

    self.current_movement = Vector3()
    self.offset = Vector3(0.5,-1.75,0)

    self.fx = {}
    self.enabled = false

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("KeyUp", self, self.KeyUp)

    Network:Subscribe("items/ToggleEquippedCloudStriderBoots", self, self.ToggleEquippedCloudStriderBoots)

end

function cCloudStriderBoots:KeyUp(args)

    if not self.enabled then return end

    if args.key == VirtualKey.Space then

        if not self.trying_to_fly then
            self.flight_enable_timer:Restart()
            self.trying_to_fly = true
        elseif self.trying_to_fly and self.flight_enable_timer:GetSeconds() < self.flight_enable_window then
            self.trying_to_fly = false
            self.flying = not self.flying
            if self.flying then
                self.current_movement = Vector3(0, 20, 0)
            else
                self.current_movement = Vector3(self.current_movement.x, -20, self.current_movement.z)
                self.obj:SetPosition(Vector3())
            end
        end

    end

end

function cCloudStriderBoots:ToggleEquippedCloudStriderBoots(args)
    self.enabled = args.equipped
    self.sync_timer:Restart()

    if self.enabled and not self.obj and not self.lpi then
        self.obj = ClientStaticObject.Create({
            position = LocalPlayer:GetPosition() - Vector3(0,5,0), 
            angle = Angle(),
            model = " ",
            collision = "34x09.flz/go003_lod1-a_col.pfx"
        })
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    elseif not self.enabled and IsValid(self.obj) and self.lpi then
        Events:Unsubscribe(self.lpi)
        self.lpi = nil
        self.obj:Remove()
        self.obj = nil
        self.flying = false
    end

end

function cCloudStriderBoots:Render(args)
    for k, data in pairs(self.fx) do
        if IsValid(data.player) then
            data.effect:SetPosition(data.player:GetPosition() + self.offset)
        end
    end

    if self.enabled then

        if self.flight_enable_timer:GetSeconds() > self.flight_enable_window then
            self.trying_to_fly = false
        end

        if not self.flying then
            if IsValid(self.object) then self.object:SetPosition(Vector3()) end
            return
        end

        local speed = self.speed

        if Key:IsDown(VirtualKey.Shift) then
            speed = speed * self.shift_mod
        end

        local velo = self.current_movement:Normalized() * speed
        LocalPlayer:SetLinearVelocity(velo)

        self.current_movement = Vector3()

        LocalPlayer:SetBaseState(AnimationState.SFall)

        local angle = Camera:GetAngle()
        angle.roll = 0
        angle.pitch = 0

        LocalPlayer:SetAngle(angle)
        
        -- Put object under so camera doesn't go crazy
        if IsValid(self.obj) then self.obj:SetPosition(LocalPlayer:GetPosition() - Vector3(0,1.5,0)) end

        local ray = Physics:Raycast(LocalPlayer:GetPosition(), Vector3.Down, 0, 0.2)

        if ray.distance < 0.2 then
            self.flying = false
        end

        if self.sync_timer:GetSeconds() > self.sync_interval then
            Network:Send(var("items/CloudStriderBootsDecreaseDura"):get())
            self.sync_timer:Restart()
        end

    end
end

function cCloudStriderBoots:LocalPlayerInput(args)
    if self.movement[args.input] then
        if args.input ~= Action.Jump and args.input ~= Action.Crouch then
            self.current_movement = self.current_movement + Camera:GetAngle() * self.movement[args.input]
        else
            self.current_movement = self.current_movement + self.movement[args.input]
        end
    end
end

function cCloudStriderBoots:CheckPlayer(p)

    local enabled = p:GetValue("CloudStriderBootsEquipped")
    local steam_id = tostring(p:GetSteamId())

    if enabled and not self.fx[steam_id] then
        self.fx[steam_id] = 
        {
            effect = ClientParticleSystem.Create(
				AssetLocation.Game, {
					position = p:GetPosition(),
					angle = Angle(),
					path = "fx_exp_resource_fueldepot_fire_03.psmb"
                }),
            player = p
        }
    elseif not enabled and self.fx[steam_id] then
        self.fx[steam_id].effect:Remove()
        self.fx[steam_id] = nil
    end

    local num_fx = count_table(self.fx)
    
    if num_fx > 0 and not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    elseif num_fx == 0 and self.render then
        Events:Unsubscribe(self.render)
        self.render = nil
    end

end

function cCloudStriderBoots:SecondTick()

    for p in Client:GetStreamedPlayers() do
        self:CheckPlayer(p)
    end

    self:CheckPlayer(LocalPlayer)

end

function cCloudStriderBoots:ModuleUnload()
    for k,v in pairs(self.fx) do v.effect:Remove() end
    if IsValid(self.obj) then self.obj:Remove() end
end



cCloudStriderBoots = cCloudStriderBoots()