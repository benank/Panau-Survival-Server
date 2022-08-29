class "ShootTargetBehavior"
ShootTargetBehavior.name = "ShootTargetBehavior"

function ShootTargetBehavior:__init(actor_profile_instance)
    getter_setter(self, "active")
    self.shooting = false
    self.reloading = false
    self.reloading_timer = Timer()
    self.reload_time = 2000
    self.delaying = false
    self.delaying_timer = Timer()
    self.actor_profile_instance = actor_profile_instance
    self.min_duration = 0
    self.shooting_timer = Timer()
    self.turning = false
    self.fire_next_frame = true
    self.has_los = false
    self.los_timer = Timer()
    self.los_delay = 250 -- how often to check for LoS & loss of LoS

    self:DeclareNetworkSubscriptions()
end

function ShootTargetBehavior:DeclareNetworkSubscriptions()
    self.actor_profile_instance.actor:SubscribeToStateEvent("StopShootingTarget", self, self.StopShootingTarget)
end

function ShootTargetBehavior:ShootTarget(data)
    --Chat:Print("Entered ShootTarget", Color.Red)
    self.target = data.target
    self.shooting = true
    self.has_los = false
    self.min_duration = data.min_duration
    self.shooting_timer:Restart()

    if self.shoot_interval then
        Timer.Clear(self.shoot_interval)
        self.shoot_interval = nil
    end
    if self.turn_interval then
        Timer.Clear(self.turn_interval)
        self.turn_interval = nil
    end

    self.turn_interval = Timer.SetInstanceInterval(400, self, self.TurnInterval)
    self.shoot_interval = Timer.SetInstanceInterval(1, self, self.ShootInterval)

    local client_actor = self.actor_profile_instance.client_actor
    if client_actor and IsValid(client_actor) then
        client_actor:SetUpperBodyState(AnimationState.UbSAiming)
    end
end

function ShootTargetBehavior:StopShootingTarget()
    --Chat:Print("Entered StopShootingTarget in client behavior", Color.Yellow)
    self.target = nil
    self.shooting = false
    self.reloading = false
    self.delaying = false
    self.turning = false
    self.has_los = false
    self.fire_next_frame = true
    if self.turn_interval then Timer.Clear(self.turn_interval) end
    if self.shoot_interval then Timer.Clear(self.shoot_interval) end
    local client_actor = self.actor_profile_instance.client_actor
    if IsValid(client_actor) then
        client_actor:SetUpperBodyState(AnimationState.UbSIdle)
    end
end

function ShootTargetBehavior:TurnInterval()
    local client_actor = self.actor_profile_instance.client_actor
    if self.shooting and self.target and IsValid(self.target) and client_actor and IsValid(client_actor) then
        self.ideal_angle = Angle(Angle.FromVectors(Vector3.Forward, self.target:GetPosition() - client_actor:GetPosition()).yaw, 0, 0)
        local current_yaw = client_actor:GetAngle().yaw
        local yaw_dif = math.abs(self.ideal_angle.yaw - current_yaw)

        if not self.turning and yaw_dif > 0.6 then
            self:TurnToIdealYaw()
        end
        --Chat:Print("Yaw dif: " .. tostring(math.abs(self.ideal_angle.yaw - current_yaw)), Color.Aqua)
    end
end

function ShootTargetBehavior:ShootInterval()
    local client_actor = self.actor_profile_instance.client_actor
    if self.target and IsValid(self.target) and client_actor and IsValid(client_actor) then
        if self.shooting and not self.reloading then    
            self:ReloadIfNecessary()
            if self.reloading then return end

            local weapon_info = WeaponEnum:GetWeaponInfo(self.actor_profile_instance.actor.weapon_enum)
            if self.delaying and weapon_info.fire_mode == 0 then
                client_actor:SetInput(Action.FireRight, 0)
            end

            local aim_pos = self.target:GetBonePosition("ragdoll_Spine1")
            client_actor:SetAimPosition(aim_pos)

            if self.delaying and self.delaying_timer:GetMilliseconds() > weapon_info.npc_fire_rate then
                self.delaying = false
                self.fire_next_frame = true
                return
            end

            if self.delaying then return end

            self:EstablishLineOfSightIfNecessary()
            if not self.has_los then return end

            if self.fire_next_frame then
                --local color = Color(math.random(1, 254), math.random(1, 254), math.random(1, 254))
                --Chat:Print("Firing", color)
                client_actor:SetInput( Action.FireRight, 1 )
				client_actor:SetInput( Action.FireLeft, 1 )
                client_actor:SetInput( Action.Fire, 1 )
                self.delaying_timer:Restart()
                self.delaying = true
                self.fire_next_frame = false
            end
        elseif self.reloading then
            --Chat:Print("Reloading", Color.Yellow)
            if self.reloading_timer:GetMilliseconds() < self.reload_time then
                client_actor:SetInput(Action.Reload, 1)
            else
                self.reloading = false
                client_actor:SetUpperBodyState(AnimationState.UbSAiming)
            end
        end
    else
        Chat:Print("Cleared shoot interval because invalid target or client actor", Color.Red)
        Timer.Clear(self.shoot_interval)
    end
end

function ShootTargetBehavior:EstablishLineOfSightIfNecessary()
    local client_has_authority = tostring(self.target:GetSteamId()) == tostring(LocalPlayer:GetSteamId())
    
    if self.has_los and self.los_timer:GetMilliseconds() > self.los_delay then
        -- check for loss of line-of-sight
        self.los_timer:Restart()
        self.has_los = self.actor_profile_instance.actor:IsEntityInLineOfSight(self.target)

        if client_has_authority and not self.has_los then
            --Chat:Print("Lost LoS", Color.Red)
            self.actor_profile_instance.actor:AddStateEvent("LineOfSightLost")
        end
    elseif not self.has_los and self.los_timer:GetMilliseconds() > self.los_delay then
        self.los_timer:Restart()
        self.has_los = self.actor_profile_instance.actor:IsEntityInLineOfSight(self.target)

        if client_has_authority and self.has_los then
            --Chat:Print("Gained LoS", Color.LawnGreen)
            --Network:Send("npc/ActorAcquiredLineOfSight" .. tostring(self.actor_profile_instance.actor.actor_id))
            self.actor_profile_instance.actor:AddStateEvent("LineOfSightGained")
        end
    end

    self.actor_profile_instance.actor:SyncStateEventsIfNecessary()
end

function ShootTargetBehavior:ReloadIfNecessary()
    local ammo_clip = self.actor_profile_instance.client_actor:GetEquippedWeapon().ammo_clip
    if ammo_clip <= 0 then
        --Chat:Print("Started Reloading", Color.Yellow)
        self.reloading = true
        self.reloading_timer:Restart()
        self.actor_profile_instance.client_actor:SetUpperBodyState(AnimationState.UbSReloading)
    end
end

function ShootTargetBehavior:TurnToIdealYaw()
    self.turning = true
    coroutine.wrap(function(angle)
        local timer = Timer()
        local set_angle_timer = Timer()
        local input_step = .005
        local ms = timer:GetMilliseconds()
        local duration = 1000
        local client_actor_angle_safe
        
        while(ms < duration) do
            --Chat:Print("In Turning Loop", Color.LawnGreen)
            ms = timer:GetMilliseconds()
            
            if set_angle_timer:GetMilliseconds() > 15 then
                if not IsValid(self.actor_profile_instance.client_actor) then
                    break
                end
                set_angle_timer:Restart()
                client_actor_angle_safe = Angle(self.actor_profile_instance.client_actor:GetAngle().yaw, 0, 0)
                
                local yaw_dif = math.abs(client_actor_angle_safe.yaw - self.ideal_angle.yaw)
                if yaw_dif > .02 then
                    local new_angle = Angle.Slerp(client_actor_angle_safe, self.ideal_angle, 0.085)
                    if new_angle then
                        new_angle.roll = 0
                        new_angle.pitch = 0
                        self.actor_profile_instance.client_actor:SetAngle(new_angle)
                        --local color = Color()
                        --Chat:Print("TURNING!", Color.Red)
                    else
                        Chat:Print("Invalid Angle in Turn", Color.Red)
                    end
                else
                    break
                end
            end
            
            Timer.Sleep(1)
        end

        self.turning = false
    end)(angle)
end

function ShootTargetBehavior:Remove()
    if self.shoot_interval then
        Timer.Clear(self.shoot_interval)
    end
    if self.turn_interval then
        Timer.Clear(self.turn_interval)
    end
    self.actor_profile_instance = nil
    self.target = nil
end


