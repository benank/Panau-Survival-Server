class 'cHitDetection'


local LocalPlayerBulletHit = var("LocalPlayerBulletHit")
local LocalPlayerDeath = var("LocalPlayerDeath")
local LocalPlayerExplosionHit = var("LocalPlayerExplosionHit")
local EntityBulletHit = var("EntityBulletHit")
local VehicleCollide = var("VehicleCollide")
local PostTick = var("PostTick")
local HitDetectionBulletHit = var("HitDetectionBulletHit")
local HitDetectionExplosionHit = var("HitDetectionExplosionHit")

function cHitDetection:__init()

    Events:Subscribe(LocalPlayerBulletHit:get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(LocalPlayerDeath:get(), self, self.LocalPlayerDeath)
    Events:Subscribe(LocalPlayerExplosionHit:get(), self, self.LocalPlayerExplosionHit)
    Events:Subscribe(EntityBulletHit:get(), self, self.EntityBulletHit)
    Events:Subscribe(VehicleCollide:get(), self, self.VehicleCollide)
    Events:Subscribe(PostTick:get(), self, self.PostTick)

end

function cHitDetection:PostTick(args)

    -- Collision checks for hitting things when in ragdoll

end

function cHitDetection:VehicleCollide(args)

    print("VehicleCollide")
    output_table(args)

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

        Network:Send(HitDetectionExplosionHit:get(), {
            attacker = args.attacker,
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

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end

    Network:Send(HitDetectionBulletHit:get(), {
        attacker = args.attacker,
        bone = args.bone
    })

    return false
end

cHitDetection = cHitDetection()