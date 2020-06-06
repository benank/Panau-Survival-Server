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
    Events:Subscribe(var("FireVehicleWeapon"):get(), self, self.FireVehicleWeapon)
    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
end

-- Block default weapons
function WeaponHitDetection:LocalPlayerExplosionHit(args)
    return false
end

function WeaponHitDetection:LocalPlayerBulletHit(args)
    return false
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

function WeaponHitDetection:FireVehicleWeapon(args)

    if not args.weapon_enum then
        Chat:Print("Fired with unsupported weapon", Color.Red)
        return
    end

    local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(args.weapon_enum)

    if not bullet_config then
        error(debug.traceback("No bullet configured for this weapon!"))
    end

    local num_shots = bullet_config.multi_shot or 1
    local v = LocalPlayer:GetVehicle() or LocalPlayer:GetValue("VehicleMG")

    for i = 1, num_shots do

        local bullet_data = {
            id = self.bullet_id_counter,
            weapon_enum = equipped_weapon_enum,
            velocity = bullet_config.speed,
            is_splash = bullet_config.splash ~= nil,
            bloom = self.bloom,
            angle = bullet_config.angle(Camera:GetAngle(), v:GetAngle()),
            bullet_size = bullet_config.bullet_size
        }

        local bullet = bullet_config.type(bullet_data)
        self.bullet_id_counter = self.bullet_id_counter + 1
        
        self.bloom = math.min(self.bloom + bullet_config.bloom, self.max_bloom)

        self.bullets[bullet:GetId()] = bullet

    end

end

function WeaponHitDetection:FireWeapon(args)

    local equipped_weapon_enum = WeaponEnum:GetByWeaponId(LocalPlayer:GetEquippedWeapon().id)
    if not equipped_weapon_enum then
        Chat:Print("Fired with unsupported weapon!", Color.Red)
        return
    end

    local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(equipped_weapon_enum)

    if not bullet_config then
        error(debug.traceback("No bullet configured for this weapon!"))
    end

    local num_shots = bullet_config.multi_shot or 1

    for i = 1, num_shots do

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

    end

end

-- excludes splash hits and direct splash hits
function WeaponHitDetection:LocalPlayerBulletDirectHitEntity(args)
    if args.entity_type == "Player" then
        local victim = Player.GetById(args.entity_id)
        local bone = victim:GetClosestBone(args.hit_position)

        Network:Send(var("HitDetection/DetectPlayerHit"):get(), {
            victim_steam_id = victim:GetSteamId(),
            weapon_enum = args.weapon_enum,
            bone_enum = bone,
            distance_travelled = args.distance_travelled,
            token = TOKEN
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = WeaponDamage:CalculatePlayerDamage(victim, args.weapon_enum, bone, args.distance_travelled) * 100,
            color = bone == BoneEnum.Head and Color.Red or Color.White,
            size = bone == BoneEnum.Head and 24 or nil
        })

        cHitDetectionMarker:Activate()

    elseif args.entity_type == "Vehicle" then

        Network:Send(var("HitDetection/DetectVehicleHit"):get(), {
            vehicle_id = args.entity:GetId(),
            weapon_enum = args.weapon_enum,
            distance_travelled = args.distance_travelled,
            token = TOKEN
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = WeaponDamage:CalculateVehicleDamage(args.entity, args.weapon_enum, args.distance_travelled) * 100
        })

        cHitDetectionMarker:Activate()

    end

end

function WeaponHitDetection:GameRenderOpaque(args)
    for bullet_id, bullet in pairs(self.bullets) do
        bullet:RenderLine()
    end
end

function WeaponHitDetection:Render(args)

    -- Draw bloom circle
    if self.bloom > 0 then

        local v = LocalPlayer:GetVehicle() or LocalPlayer:GetValue("VehicleMG")

        if IsValid(v) then

            local weapon_enum = cVehicleWeaponManager:IsValidVehicleWeaponAction(Action.VehicleFireLeft) or
            cVehicleWeaponManager:IsValidVehicleWeaponAction(Action.VehicleFireLeft)
        
            local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(weapon_enum)
        
            if not bullet_config then return end
    
            if bullet_config.indicator then
                cVehicleWeaponManager:DrawBloom(math.min(50, self.bloom * 5), Color(255,255,255,100))
            end
        else
            Render:DrawCircle(Render.Size / 2, math.min(50, self.bloom * 5), Color(255,255,255,100))
        end
        
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
