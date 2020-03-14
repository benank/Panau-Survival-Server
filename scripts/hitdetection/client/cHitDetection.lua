class 'cHitDetection'


local LocalPlayerBulletHit = var("LocalPlayerBulletHit")
local LocalPlayerDeath = var("LocalPlayerDeath")
local LocalPlayerExplosionHit = var("LocalPlayerExplosionHit")
local EntityBulletHit = var("EntityBulletHit")
local VehicleCollide = var("VehicleCollide")
local PostTick = var("PostTick")
local HitDetectionSyncHit = var("HitDetectionSyncHit")

function cHitDetection:__init()

    self.pending = {}
    self.sync_timer = Timer()

    Events:Subscribe(LocalPlayerBulletHit:get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(LocalPlayerDeath:get(), self, self.LocalPlayerDeath)
    Events:Subscribe(LocalPlayerExplosionHit:get(), self, self.LocalPlayerExplosionHit)
    Events:Subscribe(EntityBulletHit:get(), self, self.EntityBulletHit)
    Events:Subscribe(VehicleCollide:get(), self, self.VehicleCollide)
    Events:Subscribe(PostTick:get(), self, self.PostTick)

end

function cHitDetection:PostTick(args)

    -- Collision checks for hitting things when in ragdoll

    -- Sync damage every 100ms
    if self.sync_timer:GetMilliseconds() > 100 then

        self.sync_timer:Restart()

        if #self.pending > 0 then
            
            Network:Send(HitDetectionSyncHit:get(), {
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