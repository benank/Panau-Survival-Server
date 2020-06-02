class "WeaponHitDetection"

function WeaponHitDetection:__init()
    -- stops bullets from removing from the world so you can see where they land + other prints
    self.debug_enabled = false

    self.bloom = 0
    self.max_bloom = 100

    self.bullet_id_counter = 0
    self.bullets = {}

    Events:Subscribe("PreTick", self, self.PreTick)
    Events:Subscribe("Render", self, self.Render)

    Events:Subscribe("GameRenderOpaque", self, self.GameRenderOpaque)
    Events:Subscribe(var("LocalPlayerBulletDirectHitEntity"):get(), self, self.LocalPlayerBulletDirectHitEntity)
    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
end

function WeaponHitDetection:GetWeaponVelocity(weapon_enum)
    return self.weapon_velocities[weapon_enum]
end

function WeaponHitDetection:PreTick(args)
    for bullet_id, bullet in pairs(self.bullets) do
        if bullet:GetActive() then
            bullet:PreTick(args.delta)
        else
            if not self.debug_enabled then
                self.bullets[bullet:GetId()] = nil
                bullet:Destroy()
            end
        end
    end

    if self.bloom > 0 then
        self.bloom = math.max(
            self.bloom - math.pow(2, self.bloom * 0.4) * args.delta, 
            0)
    end
end

function WeaponHitDetection:FireWeapon(args)
    local target = LocalPlayer:GetAimTarget()

    local equipped_weapon_enum = WeaponEnum:GetByWeaponId(LocalPlayer:GetEquippedWeapon().id)
    if not equipped_weapon_enum then
        Chat:Print("Fired with unsupported weapon!", Color.Red)
    end
    if not equipped_weapon_enum then return end

    local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(equipped_weapon_enum)

    if not bullet_config then
        Chat:Print("No bullet configured for this weapon!", Color.Red)
    end

    local bullet_data = {
        id = self.bullet_id_counter,
        weapon_enum = equipped_weapon_enum,
        velocity = bullet_config.speed,
        is_splash = bullet_config.splash ~= nil,
        bloom = self.bloom,
        bullet_size = bullet_config.bullet_size
    }

    local bullet = bullet_config.type(bullet_data)
    self.bullet_id_counter = self.bullet_id_counter + 1
    
    self.bloom = math.min(self.bloom + bullet_config.bloom, self.max_bloom)

    self.bullets[bullet:GetId()] = bullet

    --Chat:Print("Fired with " .. tostring(WeaponEnum:GetDescription(equipped_weapon_enum)), Color.White)
end

-- excludes splash hits and direct splash hits
function WeaponHitDetection:LocalPlayerBulletDirectHitEntity(args)
    if args.entity_type == "Player" then
        local victim = Player.GetById(args.entity_id)
        Network:Send(var("HitDetection/DetectPlayerHit"):get(), {
            victim_steam_id = victim:GetSteamId(),
            weapon_enum = args.weapon_enum,
            bone_enum = victim:GetClosestBone(args.hit_position),
            distance_travelled = args.distance_travelled
        })

        cHitDetectionMarker:Activate()
    end

    -- TODO: add vehicle support

end

function WeaponHitDetection:GameRenderOpaque(args)
    for bullet_id, bullet in pairs(self.bullets) do
        bullet:RenderLine()
    end
end

function WeaponHitDetection:Render(args)

    -- Draw bloom circle
    if self.bloom > 0 then
        Render:DrawCircle(Render.Size / 2, math.min(50, self.bloom * 5), Color(255,255,255,100))
    end

    if self.debug_enabled then
        self:RenderDebug()
    end

end

function WeaponHitDetection:RenderDebug()
    for bullet_id, bullet in pairs(self.bullets) do
        bullet:Render()
    end
end

WeaponHitDetection = WeaponHitDetection()
