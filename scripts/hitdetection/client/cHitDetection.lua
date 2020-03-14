class 'cHitDetection'

function cHitDetection:__init()

    self.pending = {}
    self.sync_timer = Timer()

    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerDeath"):get(), self, self.LocalPlayerDeath)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
    Events:Subscribe(var("EntityBulletHit"):get(), self, self.EntityBulletHit)
    Events:Subscribe(var("VehicleCollide"):get(), self, self.VehicleCollide)
    Events:Subscribe(var("PostTick"):get(), self, self.PostTick)

    Events:Subscribe(var("HitDetection/Explosion"):get(), self, self.Explosion)

end

-- Explosions from items, like mines
function cHitDetection:Explosion(args)

    local explosive_data = ExplosiveBaseDamage[args.type]

    if explosive_data then

        local dist = args.position:Distance(args.local_position)
        dist = math.min(explosive_data.radius, dist)
        local percent_modifier = 1 - dist / explosive_data.radius

        if percent_modifier == 0 then return end

        local damage = explosive_data.damage * percent_modifier
        local knockback_effect = explosive_data.knockback * percent_modifier

        LocalPlayer:SetRagdollLinearVelocity(((args.local_position - args.position):Normalized() + Vector3(0, 1.5, 0)) * knockback_effect)

        Network:Send(var("HitDetectionSyncExplosion"):get(), {
            position = args.position,
            local_position = args.local_position,
            type = args.type
        })

    end


end

function cHitDetection:PostTick(args)

    -- Collision checks for hitting things when in ragdoll

    -- Sync damage every 100ms
    if self.sync_timer:GetMilliseconds() > 100 then

        self.sync_timer:Restart()

        if #self.pending > 0 then
            
            Network:Send(var("HitDetectionSyncHit"):get(), {
                pending = self.pending
            })

            self.pending = {}

        end

    end


end

function cHitDetection:VehicleCollide(args)

    print("VehicleCollide")
    output_table(args)

end

function cHitDetection:EntityBulletHit(args)

    -- if 0 damage, then they used the grapplehook to hit them (F)

    -- only is called for the person who shot

    print("EntityBulletHit")
    output_table(args)

end

function cHitDetection:LocalPlayerExplosionHit(args)

    if args.attacker then

        local weapon = args.attacker:GetEquippedWeapon()
        if not weapon then return end

        table.insert(self.pending, {
            attacker = args.attacker,
            bone = args.bone,
            type = WeaponHitType.Explosive
        })
    
        return false

    end

end

function cHitDetection:LocalPlayerDeath(args)

end

function cHitDetection:LocalPlayerBulletHit(args)

    if not args.bone or not BoneModifiers[args.bone.name] then return false end
    if not args.attacker then return false end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end

    table.insert(self.pending, {
        attacker = args.attacker,
        bone = args.bone,
        type = WeaponHitType.Bodyshot
    })

    return false
end

cHitDetection = cHitDetection()