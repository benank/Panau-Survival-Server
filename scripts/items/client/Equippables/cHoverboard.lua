-- "f3m06.lift01.flz/key020_01-r8.lod"

class 'cHoverboard'

function cHoverboard:__init()

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
        [Action.Jump] = Vector3.Up * 10,
        [Action.Crouch] = Vector3.Down
    }

    self.current_movement = Vector3(0,0,0)
    self.offset = Vector3(0.5,-1.75,0)

    self.fx = {}
    self.enabled = false

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("Render", self, self.Render)

    Network:Subscribe("items/ToggleEquippedHoverboard", self, self.ToggleEquippedHoverboard)

end

function cHoverboard:ToggleEquippedHoverboard(args)
    self.enabled = args.equipped
    self.sync_timer:Restart()

    if self.enabled and not self.obj and not self.lpi then
        self.obj = ClientStaticObject.Create({
            position = LocalPlayer:GetPosition() - Vector3(0,1,0), 
            angle = LocalPlayer:GetAngle(),
            model = "f3m06.lift01.flz/key020_01-r8.lod",
            collision = "f3m06.lift01.flz/key020_01_lod1-r8_col.pfx",
            fixed = false
        })
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    elseif not self.enabled and IsValid(self.obj) and self.lpi then
        Events:Unsubscribe(self.lpi)
        self.lpi = nil
        self.obj:Remove()
        self.obj = nil
    end

end

function cHoverboard:Render(args)
    for k, data in pairs(self.fx) do
        if IsValid(data.player) then
            data.effect:SetPosition(data.player:GetPosition() + self.offset)
        end
    end

    if self.enabled then

        local speed = self.speed

        if Key:IsDown(VirtualKey.Shift) then
            speed = speed * self.shift_mod
        end

        local left_foot = LocalPlayer:GetBonePosition("ragdoll_LeftFoot")
        local right_foot = LocalPlayer:GetBonePosition("ragdoll_RightFoot")
        local angle_between = Angle.FromVectors(left_foot - right_foot, Vector3.Forward)

        self.obj:SetAngle(-angle_between)

        local velo = self.current_movement:Normalized() * speed or Vector3()

        if IsNaN(velo) then velo = Vector3() end

        local board_position = left_foot + self.obj:GetAngle() * Vector3(0, 0, 0.2)

        local ray = Physics:Raycast(board_position + velo - Vector3(0, 0.25, 0), Vector3.Down, 0, 500)

        board_position = board_position + velo
        local new_pos = Vector3(board_position.x, ray.position.y + 1, board_position.z)

        self.obj:SetPosition(new_pos)

        --LocalPlayer:SetLinearVelocity(velo)

        self.current_movement = Vector3()

        --LocalPlayer:SetBaseState(AnimationState.SFall)

        local angle = Camera:GetAngle()
        angle.roll = 0
        angle.pitch = 0

        LocalPlayer:SetAngle(angle * Angle(-math.pi / 2, 0, 0))
        
        -- Put object under so camera doesn't go crazy

        if self.sync_timer:GetSeconds() > self.sync_interval then
            Network:Send(var("items/HoverboardDecreaseDura"):get())
            self.sync_timer:Restart()
        end

    end
end

function cHoverboard:LocalPlayerInput(args)
    if self.movement[args.input] then
        if args.input ~= Action.Jump and args.input ~= Action.Crouch then
            local angle = Camera:GetAngle()
            angle.roll = 0
            angle.pitch = 0
    
            self.current_movement = self.current_movement + angle * self.movement[args.input]
        else
            self.current_movement = self.current_movement + self.movement[args.input]
        end
        print(self.current_movement)
        return false
    end
end

function cHoverboard:CheckPlayer(p)

    local enabled = p:GetValue("HoverboardEquipped")
    local steam_id = tostring(p:GetSteamId())

    if enabled and not self.fx[steam_id] then
        self.fx[steamid] = ClientStaticObject.Create({
            position = LocalPlayer:GetPosition() - Vector3(0,1,0), 
            angle = LocalPlayer:GetAngle(),
            model = "f3m06.lift01.flz/key020_01-r8.lod",
            collision = ""
        })

    elseif not enabled and self.fx[steam_id] then
        self.fx[steam_id]:Remove()
        self.fx[steam_id] = nil
    end

end

function cHoverboard:SecondTick()

    for p in Client:GetStreamedPlayers() do
        self:CheckPlayer(p)
    end

end

function cHoverboard:ModuleUnload()
    if IsValid(self.obj) then self.obj:Remove() end
end



cHoverboard = cHoverboard()