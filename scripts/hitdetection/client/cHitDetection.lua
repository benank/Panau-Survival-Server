class 'cHitDetection'

function cHitDetection:__init()

    self.pending = {}
    self.sync_timer = Timer()

    self.old_health = LocalPlayer:GetHealth()
    self.max_damage_screen_alpha = 150
    self.damage_screen_time = 1

    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerDeath"):get(), self, self.LocalPlayerDeath)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
    Events:Subscribe(var("EntityBulletHit"):get(), self, self.EntityBulletHit)
    Events:Subscribe(var("VehicleCollide"):get(), self, self.VehicleCollide)
    Events:Subscribe(var("PostRender"):get(), self, self.PostRender)

    Events:Subscribe(var("HitDetection/Explosion"):get(), self, self.Explosion)

end


function cHitDetection:CheckHealth()
    -- Called on PostTick to check for health changes and apply a red screen

    if LocalPlayer:GetValue("Loading") then
        self.old_health = LocalPlayer:GetHealth()
        return
    end

    local current_health = LocalPlayer:GetHealth()

    if current_health < self.old_health then

        if self.damage_screen_timer then
            self.damage_screen_timer:Restart()
        else
            self.damage_screen_timer = Timer()
        end
        
    end

    self.old_health = current_health

    if self.damage_screen_timer and self.damage_screen_timer:GetSeconds() < self.damage_screen_time then
        local alpha = self.max_damage_screen_alpha - 
            self.max_damage_screen_alpha * (self.damage_screen_timer:GetSeconds() / self.damage_screen_time)
        Render:FillArea(Vector2(0,0), Render.Size, Color(255, 0, 0, alpha))
    end

end

-- Explosions from items, like mines
function cHitDetection:Explosion(args)

    if LocalPlayer:GetValue(var("InSafezone"):get()) then return end

    local explosive_data = ExplosiveBaseDamage[args.type]

    if explosive_data then

        local from_pos = args.position + Vector3.Up
        local to_pos = LocalPlayer:GetBonePosition(var("ragdoll_Spine"):get())
        local diff = (to_pos - from_pos):Normalized()
        local ray = Physics:Raycast(from_pos, diff, 0, 15, false)

        local in_fov = ray.entity and ray.entity.__type == "LocalPlayer"
    
        local dist = args.position:Distance(args.local_position)
        dist = math.min(explosive_data.radius, math.max(0, dist - 5))
        local percent_modifier = 1 - (dist / (explosive_data.radius / 2))
    
        if percent_modifier == 0 then return end

        local knockback_effect = explosive_data.knockback * percent_modifier

        local base_state = LocalPlayer:GetBaseState()

        if in_fov and not LocalPlayer:InVehicle() 
        and not LocalPlayer:GetValue("StuntingVehicle")
        and base_state ~= AnimationState.SReeledInIdle
        and base_state ~= AnimationState.SReelFlight
        and base_state ~= AnimationState.SHangstuntIdle then
            LocalPlayer:SetRagdollLinearVelocity(
                LocalPlayer:GetLinearVelocity() + ((args.local_position - args.position):Normalized() + Vector3(0, 1.5, 0)) * knockback_effect)
        end

        Network:Send(var("HitDetectionSyncExplosion"):get(), {
            position = args.position,
            local_position = args.local_position,
            type = args.type,
            in_fov = in_fov,
            attacker_id = args.attacker_id
        })

    end


end

function cHitDetection:PostRender(args)

    self:CheckHealth()
    -- Collision checks for hitting things when in ragdoll

    -- Sync damage every 100ms
    if self.sync_timer:GetMilliseconds() > 100 then

        if count_table(self.pending) > 0 then
            
            Network:Send(var("HitDetectionSyncHit"):get(), {
                pending = self.pending
            })

            self.pending = {}
            self.sync_timer:Restart()

        end

    end


end

function cHitDetection:VehicleCollide(args)

    --print("VehicleCollide")
    --output_table(args)

end

function cHitDetection:EntityBulletHit(args)

    -- if 0 damage, then they used the grapplehook to hit them (F)

    -- only is called for the person who shot

    --print("EntityBulletHit")
    --output_table(args)

end

function cHitDetection:LocalPlayerExplosionHit(args)

    if args.attacker then

        local weapon = args.attacker:GetEquippedWeapon()
        if not weapon then return end

        table.insert(self.pending, {
            attacker = args.attacker,
            bone = args.bone,
            type = WeaponHitType.Explosive,
            damage = args.damage
        })
    
        return false

    end

end

function cHitDetection:LocalPlayerDeath(args)

end

function cHitDetection:LocalPlayerBulletHit(args)

    if not args.bone or not BoneModifiers[args.bone.name] then return false end
    if not args.attacker then return false end

    table.insert(self.pending, {
        attacker = args.attacker,
        bone = args.bone,
        type = WeaponHitType.Bodyshot
    })

    return false
end

cHitDetection = cHitDetection()