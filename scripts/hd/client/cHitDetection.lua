class "HitDetection"

function HitDetection:__init()
    -- stops bullets from removing from the world so you can see where they land + other prints
    self.debug_enabled = true

    self.weapon_bullets = {
        --[WeaponEnum.MachineGun] = InstantBullet
        [WeaponEnum.MachineGun] = ProjectileBullet,
        [WeaponEnum.PanayRocketLauncher] = ProjectileBullet,
        [WeaponEnum.RocketLauncher] = ProjectileBullet
    }

    self.weapon_velocities = {
        [WeaponEnum.MachineGun] = 550,
        [WeaponEnum.PanayRocketLauncher] = 100, -- untested
        [WeaponEnum.RocketLauncher] = 100 -- dont change this, it's the base-game velocity
    }

    self.splash_weapons = {
        [WeaponEnum.PanayRocketLauncher] = true,
        [WeaponEnum.RocketLauncher] = true
    }

    self.bullet_id_counter = 0
    self.bullets = {}

    Events:Subscribe("PreTick", self, self.PreTick)
    if self.debug_enabled then
        Events:Subscribe("Render", self, self.RenderDebug) -- for debug / testing
    end
    Events:Subscribe("LocalPlayerBulletDirectHitEntity", self, self.LocalPlayerBulletDirectHitEntity)
    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
end

function HitDetection:GetWeaponVelocity(weapon_enum)
    return self.weapon_velocities[weapon_enum]
end

function HitDetection:PreTick(args)
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
end

function HitDetection:FireWeapon(args)
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
        is_splash = self.splash_weapons[equipped_weapon_enum] != nil
    }
    local bullet = bullet_class(bullet_data)
    self.bullet_id_counter = self.bullet_id_counter + 1
    
    self.bullets[bullet:GetId()] = bullet

    --Chat:Print("Fired with " .. tostring(WeaponEnum:GetDescription(equipped_weapon_enum)), Color.White)
end

-- excludes splash hits and direct splash hits
function HitDetection:LocalPlayerBulletDirectHitEntity(args)
    if args.entity_type == "Player" then
        local victim = Player.GetById(args.entity_id)
        Network:Send("HitDetection/DetectPlayerHit", {
            victim_steam_id = victim:GetSteamId(),
            weapon_enum = args.weapon_enum,
            bone_enum = victim:GetClosestBone(args.hit_position)
        })
    end

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

function HitDetection:RenderDebug()
    for bullet_id, bullet in pairs(self.bullets) do
        bullet:Render()
    end
end

HitDetection = HitDetection()
