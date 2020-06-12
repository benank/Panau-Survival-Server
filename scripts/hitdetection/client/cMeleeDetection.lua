class 'cMeleeDetection'

local DEBUG_ON = false

function cMeleeDetection:__init()

    self.melee_config = 
    {
        [DamageEntity.MeleeGrapple] = 
        {
            bone = "ragdoll_LeftHand", -- Bone to use
            bone_angle = Angle(math.pi / 2, 0, 0), -- Angle offset
            length = 1.25, -- Length of hit
            cooldown = 0.5, -- Delay before next melee
            hit_types = {
                ["Player"] = true,
                ["ClientStaticObject"] = true
            },
            event_name = var("HitDetection/MeleeGrappleHit")
        },
        [DamageEntity.MeleeKick] = 
        {
            bone = "ragdoll_RightFoot", -- Bone to use
            bone_angle = Angle(), -- Angle offset
            length = 1.25, -- Length of hit
            cooldown = 1, -- Delay before next melee
            hit_types = {
                ["Player"] = true
            },
            event_name = var("HitDetection/MeleeStandingKickHit")
        },
        [DamageEntity.MeleeSlidingKick] = 
        {
            bone = "ragdoll_RightFoot", -- Bone to use
            bone_angle = Angle(-math.pi / 2, 0, 0), -- Angle offset
            length = 1.25, -- Length of hit
            cooldown = 1, -- Delay before next melee
            hit_types = {
                ["Player"] = true
            },
            event_name = var("HitDetection/MeleeSlidingKickHit")
        },
    }

    self.recent_hits = {} -- Recently hit players

    self.allowed_states = 
    {
        [AnimationState.SUprightIdle] = true,
        [AnimationState.SUprightBasicNavigation] = true,
        [AnimationState.SDash] = true
    }

    self.grapple_attack_states = 
    {
        [AnimationState.SGrappleSmashLeft] = true,
        [AnimationState.SGrappleSmashRight] = true
    }

    self.last_kick_time = Client:GetElapsedSeconds()
    self.kick_cooldown_time = 0

    Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function cMeleeDetection:LocalPlayerInput(args)

    local current_time = Client:GetElapsedSeconds()
    
    if args.input == Action.Kick and current_time - self.last_kick_time > self.kick_cooldown_time then

        self.recent_hits = {}

        if LocalPlayer:GetValue("GrapplehookEnabled") and not LocalPlayer:GetValue("InSafezone") then

            self:PerformGrappleAttack()
            self.last_kick_time = current_time

            return
        end

        if not self:CanPerformKick() then return end

        self.last_kick_time = current_time

        if Key:IsDown(VirtualKey.LShift) then
            self:PerformSlidingKick()
        else
            self:PerformStandingKick()
        end

    end

end

function cMeleeDetection:PerformGrappleAttack()

    self:ScanForHit(DamageEntity.MeleeGrapple)

end

function cMeleeDetection:PerformSlidingKick()

    LocalPlayer:SetBaseState(AnimationState.SCloseCombatRunningKick)
    self:ScanForHit(DamageEntity.MeleeSlidingKick)

end

function cMeleeDetection:PerformStandingKick()

    LocalPlayer:SetBaseState(AnimationState.SCloseCombatKick)
    self:ScanForHit(DamageEntity.MeleeKick)

end

function cMeleeDetection:FireRay(pos, angle, length)

    local ray

    local ang = angle * Angle(0, -math.pi / 12, 0)

    for i = 1, 3 do

        ray_cast = Physics:Raycast(pos, ang * Vector3.Forward, 0, length)

        if DEBUG_ON then
            Render:DrawLine(pos, ray_cast.position, Color.Red)
        end

        if ray_cast.entity then
            ray = ray_cast
        end

        ang = ang * Angle(0, math.pi / 12, 0)

    end

    return ray

end

function cMeleeDetection:ScanForHit(type)

    local type_data = self.melee_config[type]

    self.kick_cooldown_time = type_data.cooldown

    local sub
    sub = Events:Subscribe("GameRender", function(args)
    
        local pos = LocalPlayer:GetBonePosition(type_data.bone)
        local angle = LocalPlayer:GetBoneAngle(type_data.bone) * type_data.bone_angle

        local ray = self:FireRay(pos, angle, type_data.length) or {}

        if ray.entity then

            if type == DamageEntity.MeleeGrapple and not self.grapple_attack_states[LocalPlayer:GetBaseState()] then return end

            if type_data.hit_types[ray.entity.__type] and not self.recent_hits[ray.entity:GetId()] then

                if ray.entity.__type == "Player" then
                    -- Hit player, send to server
                    Network:Send(type_data.event_name:get(), {victim_id = tostring(ray.entity:GetSteamId()), token = TOKEN:get()})
                    self.recent_hits[ray.entity:GetId()] = true

                    cDamageText:Add({
                        position = ray.position + Vector3(0, 0.5, 0),
                        amount = WeaponDamage:CalculateMeleeDamage(ray.entity, type) * 100
                    })

                    cHitDetectionMarker:Activate()

                    ClientEffect.Play(AssetLocation.Game, {
                        position = ray.position,
                        angle = ray.entity:GetAngle(),
                        effect_id = 421
                    })

                elseif ray.entity.__tyoe == "ClientStaticObject" and type == DamageEntity.MeleeGrapple then

                    -- Break open vending machine

                end

            end

        end

        local current_time = Client:GetElapsedSeconds()
        if current_time - self.last_kick_time > self.kick_cooldown_time then
            Events:Unsubscribe(sub)
        end
    end)

end

function cMeleeDetection:CanPerformKick()

    local velocity = -LocalPlayer:GetAngle() * LocalPlayer:GetLinearVelocity()
    local forward_velocity = -velocity.z

    return forward_velocity < 15 
    and not LocalPlayer:InVehicle() 
    and LocalPlayer:GetHealth() > 0
    and not LocalPlayer:GetValue("Loading") 
    and math.abs(velocity.y) < 5
    and LocalPlayer:GetPosition().y > 200.15 
    and LocalPlayer:GetState() == PlayerState.OnFoot
    and not LocalPlayer:GetValue("InSafezone")
    and self.allowed_states[LocalPlayer:GetBaseState()]
    and not LocalPlayer:GetValue("GrapplehookEnabled")

end

cMeleeDetection = cMeleeDetection()