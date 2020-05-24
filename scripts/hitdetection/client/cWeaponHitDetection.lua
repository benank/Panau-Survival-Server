class "WeaponHitDetection"

function WeaponHitDetection:__init()
    -- stops bullets from removing from the world so you can see where they land + other prints
    self.debug_enabled = true

    self.bloom = 0

    self.weapon_bullets = {
        [WeaponEnum.MachineGun] = ProjectileBullet,
        [WeaponEnum.Revolver] = ProjectileBullet,
        [WeaponEnum.Handgun] = ProjectileBullet,
        [WeaponEnum.BubbleGun] = ProjectileBullet,
        [WeaponEnum.PanayRocketLauncher] = ProjectileBullet,
        [WeaponEnum.RocketLauncher] = ProjectileBullet
    }

    self.weapon_velocities = {
        [WeaponEnum.BubbleGun] = 1.5,
        [WeaponEnum.Handgun] = 300,
        [WeaponEnum.Revolver] = 400,
        [WeaponEnum.MachineGun] = 550,
        [WeaponEnum.PanayRocketLauncher] = 100, -- untested
        [WeaponEnum.RocketLauncher] = 100 -- dont change this, it's the base-game velocity
    }

    self.weapon_blooms = {
        [WeaponEnum.BubbleGun] = 10,
        [WeaponEnum.Handgun] = 1.2,
        [WeaponEnum.Revolver] = 3,
        [WeaponEnum.MachineGun] = 1 -- Bloom per shot
    }

    self.splash_weapons = {
        [WeaponEnum.PanayRocketLauncher] = true,
        [WeaponEnum.BubbleGun] = true,
        [WeaponEnum.RocketLauncher] = true
    }

    self.bullet_id_counter = 0
    self.bullets = {}

    Events:Subscribe("PreTick", self, self.PreTick)
    if self.debug_enabled then
        Events:Subscribe("Render", self, self.RenderDebug) -- for debug / testing
    end
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
        self.bloom = math.max(0, self.bloom - math.pow(2, self.bloom * 0.5) * args.delta)
    end
end

function WeaponHitDetection:FireWeapon(args)
    local target = LocalPlayer:GetAimTarget()

    local equipped_weapon_enum = WeaponEnum:GetByWeaponId(LocalPlayer:GetEquippedWeapon().id)
    if not equipped_weapon_enum then
        Chat:Print("Fired with unsupported weapon!", Color.Red)
    end
    if not equipped_weapon_enum then return end

    local bullet_class = self.weapon_bullets[equipped_weapon_enum]
    if not bullet_class then
        Chat:Print("No bullet configured for this weapon!", Color.Red)
    end

    local bullet_data = {
        id = self.bullet_id_counter,
        weapon_enum = equipped_weapon_enum,
        velocity = self.weapon_velocities[equipped_weapon_enum],
        is_splash = self.splash_weapons[equipped_weapon_enum] ~= nil,
        bloom = self.bloom
    }
    local bullet = bullet_class(bullet_data)
    self.bullet_id_counter = self.bullet_id_counter + 1
    
    self.bloom = self.bloom + self.weapon_blooms[equipped_weapon_enum]

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

    -- debugging / testing by using a ClientActor instead of a Player
    --[[

    ]]
    if self.debug_enabled then
        if args.entity_type == "ClientActor" then
            local victim = ClientActor.GetById(args.entity_id)
            Network:Send("HitDetection/DetectPlayerHit", {
                victim_steam_id = 34,
                weapon_enum = args.weapon_enum,
                bone_enum = victim:GetClosestBone(args.hit_position)
            })
        end
    end
end

function WeaponHitDetection:RenderDebug()
    for bullet_id, bullet in pairs(self.bullets) do
        bullet:Render()
    end
end

HitDetection = HitDetection()
