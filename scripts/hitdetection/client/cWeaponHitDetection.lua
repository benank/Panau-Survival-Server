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
    Events:Subscribe(var("LocalPlayerBulletSplashEntityHit"):get(), self, self.LocalPlayerBulletSplashEntityHit)
    Events:Subscribe(var("LocalPlayerBulletSplash"):get(), self, self.LocalPlayerBulletSplash)
    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
    Events:Subscribe(var("FireVehicleWeapon"):get(), self, self.FireVehicleWeapon)
    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
    Events:Subscribe(var("HitDetection/SplashHitDrone"):get(), self, self.SplashHitDrone)
    
    Events:Subscribe(var("HitDetection/DroneShootMachineGun"):get(), self, self.DroneShootMachineGun)

    Events:Subscribe("LocalPlayerDeath", self, self.LocalPlayerDeath)
    Events:Subscribe("EntitySpawn", self, self.EntitySpawn)
end

function WeaponHitDetection:EntitySpawn(args)
    if args.entity.__type ~= "Player" and args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    
    -- Resubscribe to ensure they work
    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
end

function WeaponHitDetection:LocalPlayerDeath()
    -- Resubscribe to ensure they work
    Events:Subscribe(var("LocalPlayerBulletHit"):get(), self, self.LocalPlayerBulletHit)
    Events:Subscribe(var("LocalPlayerExplosionHit"):get(), self, self.LocalPlayerExplosionHit)
end

function WeaponHitDetection:CheckPlayerSplash(args)

    local radius = WeaponDamage.weapon_damages[args.weapon_enum].radius

    local player = args.player

    local ray = Physics:Raycast(
        args.hit_position, 
        (player:GetBonePosition(BoneEnum.Spine1) - args.hit_position),
        0, radius, false)

    if ray.distance < radius
    and ray.entity
    and ((ray.entity.__type == "Player" and ray.entity == player) 
    or (ray.entity.__type == "LocalPlayer" and ray.entity == player)) then

        local damage = WeaponDamage:CalculatePlayerDamage(player, args.weapon_enum, BoneEnum.Spine1, args.distance_travelled, LocalPlayer)
        local falloff = 1 - ray.distance / radius
        damage = damage * falloff

        if damage > 0 then

            -- Hit the player with the splash damage
            Network:Send(var("HitDetection/DetectPlayerSplashHit"):get(), {
                victim_steam_id = tostring(player:GetSteamId()),
                damage_falloff = falloff,
                weapon_enum = args.weapon_enum,
                token = TOKEN:get()
            })

            -- Preemptively add damage text and indicator so it feels responsive
            cDamageText:Add({
                position = ray.position,
                amount = damage * 100
            })

            cHitDetectionMarker:Activate()

        end

    end

end

-- Splash weapon hit drone from Localplayer
function WeaponHitDetection:SplashHitDrone(args)

    if args.weapon_enum == WeaponEnum.Drone_Rockets then return end
    
    local damage = WeaponDamage:CalculateDroneDamage(args.weapon_enum, args.distance_travelled, LocalPlayer)
    local falloff = 1 - args.drone_distance / args.radius
    damage = damage * falloff

    if damage > 0 then

        -- Hit the player with the splash damage
        Network:Send(var("HitDetection/DetectDroneSplashHit"):get(), {
            drone_id = args.drone_id,
            weapon_enum = args.weapon_enum,
            damage_falloff = falloff,
            distance_travelled = args.distance_travelled,
            hit_position = args.hit_position,
            token = TOKEN:get()
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = damage * 100
        })

        cHitDetectionMarker:Activate()

    end

end

function WeaponHitDetection:LocalPlayerBulletSplash(args)

    --Thread(function()
    
    local radius = WeaponDamage.weapon_damages[args.weapon_enum].radius

    if not radius then return end

    for player in Client:GetStreamedPlayers() do

        local args_copy = deepcopy(args)
        args_copy.player = player
        self:CheckPlayerSplash(args_copy)
            --Timer.Sleep(5)

    end

    local args_copy = deepcopy(args)
    args_copy.radius = radius
    Events:Fire("HitDetection/BulletSplash", args_copy)
    args_copy.player = LocalPlayer
    self:CheckPlayerSplash(args_copy)

    for vehicle in Client:GetVehicles() do

        local ray = Physics:Raycast(
            args.hit_position, 
            (vehicle:GetPosition() - args.hit_position),
            0, radius)

        if ray.distance < radius
        and ray.entity
        and ray.entity.__type == "Vehicle"
        and ray.entity == vehicle then

            local damage = WeaponDamage:CalculateVehicleDamage(vehicle, args.weapon_enum, args.distance_travelled, LocalPlayer)
            local falloff = 1 - ray.distance / radius
            damage = damage * falloff

            if damage > 0 then

                -- Hit the player with the splash damage
                Network:Send(var("HitDetection/DetectVehicleSplashHit"):get(), {
                    vehicle_id = vehicle:GetId(),
                    damage_falloff = falloff,
                    weapon_enum = args.weapon_enum,
                    token = TOKEN:get()
                })

                -- Preemptively add damage text and indicator so it feels responsive
                cDamageText:Add({
                    position = ray.position,
                    amount = damage * 100
                })

                cHitDetectionMarker:Activate()

            end

            --Timer.Sleep(5)

        end

    end

    --end)
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
            weapon_enum = args.weapon_enum,
            velocity = bullet_config.speed,
            is_splash = bullet_config.splash ~= nil,
            bloom = self.bloom,
            angle = bullet_config.angle(Camera:GetAngle(), v:GetAngle(), v:GetModelId()),
            bullet_size = bullet_config.bullet_size
        }

        local bullet = bullet_config.type(bullet_data)
        self.bullet_id_counter = self.bullet_id_counter + 1
        
        local bloom_to_add = bullet_config.bloom

        if self.bloom < 4 then
            bloom_to_add = bloom_to_add * 0.4
        end

        self.bloom = math.min(self.bloom + bloom_to_add, self.max_bloom)

        self.bullets[bullet:GetId()] = bullet

    end

end

function WeaponHitDetection:DroneShootMachineGun(args)
    
    local weapon_enum = WeaponEnum.Drone_MachineGun
    local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(weapon_enum)

    if not bullet_config then
        error(debug.traceback("No bullet configured for this weapon!"))
    end

    local num_shots = bullet_config.multi_shot or 1

    for i = 1, num_shots do

        local bullet_data = {
            start_position = args.position,
            angle = args.angle,
            ignore_localplayer = false,
            id = self.bullet_id_counter,
            weapon_enum = weapon_enum,
            velocity = bullet_config.speed,
            is_splash = bullet_config.splash ~= nil,
            damage_mod = args.damage_modifier,
            bloom = 0,
            bullet_size = bullet_config.bullet_size
        }

        local bullet = bullet_config.type(bullet_data)
        self.bullet_id_counter = self.bullet_id_counter + 1
        
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
        
        local bloom_to_add = bullet_config.bloom

        if self.bloom < 2 then
            bloom_to_add = bloom_to_add * 0.5
        end

        self.bloom = math.min(self.bloom + bloom_to_add, self.max_bloom)

        self.bullets[bullet:GetId()] = bullet

    end

end

function WeaponHitDetection:LocalPlayerBulletSplashEntityHit(args)

    if args.entity_type == "Player" then
        local victim = Player.GetById(args.entity_id)

        local damage = WeaponDamage:CalculatePlayerDamage(victim, args.weapon_enum, BoneEnum.Spine1, args.distance_travelled, LocalPlayer) * 100

        if damage == 0 then return end

        Network:Send(var("HitDetection/DetectPlayerSplashHit"):get(), {
            victim_steam_id = tostring(victim:GetSteamId()),
            weapon_enum = args.weapon_enum,
            distance_travelled = args.distance_travelled,
            token = TOKEN:get()
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = damage
        })

        cHitDetectionMarker:Activate()

    elseif args.entity_type == "Vehicle" then

        local damage = WeaponDamage:CalculateVehicleDamage(args.entity, args.weapon_enum, args.distance_travelled, LocalPlayer) * 100

        if damage == 0 then return end

        Network:Send(var("HitDetection/DetectVehicleSplashHit"):get(), {
            vehicle_id = args.entity:GetId(),
            weapon_enum = args.weapon_enum,
            distance_travelled = args.distance_travelled,
            token = TOKEN:get(),
            hit_position = args.hit_position
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = damage
        })

        cHitDetectionMarker:Activate()

    end

end

-- excludes splash hits and direct splash hits
function WeaponHitDetection:LocalPlayerBulletDirectHitEntity(args)
    if args.entity_type == "Player" and args.weapon_enum ~= WeaponEnum.Drone_MachineGun then
        local victim = Player.GetById(args.entity_id)
        local bone = victim:GetClosestBone(args.hit_position)

        local damage = WeaponDamage:CalculatePlayerDamage(victim, args.weapon_enum, bone, args.distance_travelled, LocalPlayer) * 100

        if damage == 0 then return end

        Network:Send(var("HitDetection/DetectPlayerHit"):get(), {
            victim_steam_id = tostring(victim:GetSteamId()),
            weapon_enum = args.weapon_enum,
            bone_enum = bone,
            distance_travelled = args.distance_travelled,
            token = TOKEN:get()
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = damage,
            color = bone == BoneEnum.Head and Color.Red or Color.White,
            size = bone == BoneEnum.Head and 24 or nil
        })

        cHitDetectionMarker:Activate()

    elseif args.entity_type == "Vehicle" and args.weapon_enum ~= WeaponEnum.Drone_MachineGun then

        local damage = WeaponDamage:CalculateVehicleDamage(args.entity, args.weapon_enum, args.distance_travelled, LocalPlayer) * 100

        if damage == 0 then return end

        Network:Send(var("HitDetection/DetectVehicleHit"):get(), {
            vehicle_id = args.entity:GetId(),
            weapon_enum = args.weapon_enum,
            distance_travelled = args.distance_travelled,
            token = TOKEN:get()
        })

        -- Preemptively add damage text and indicator so it feels responsive
        cDamageText:Add({
            position = args.hit_position,
            amount = damage
        })

        cHitDetectionMarker:Activate()

    elseif args.entity_type == "ClientStaticObject" then
        -- Local player hit drone
        local drone = cDroneContainer:CSOIdToDrone(args.entity:GetId())
        if drone and args.weapon_enum ~= WeaponEnum.Drone_MachineGun then
            local drone_id = drone.id
            -- Bullet hit a drone

            local damage = WeaponDamage:CalculateDroneDamage(args.weapon_enum, args.distance_travelled, LocalPlayer) * 100

            if damage == 0 then return end

            Network:Send(var("HitDetection/DetectDroneHit"):get(), {
                drone_id = drone_id,
                weapon_enum = args.weapon_enum,
                distance_travelled = args.distance_travelled,
                hit_position = args.hit_position,
                token = TOKEN:get()
            })

            -- Preemptively add damage text and indicator so it feels responsive
            cDamageText:Add({
                position = args.hit_position,
                amount = damage
            })

            cHitDetectionMarker:Activate()

        end

    elseif args.weapon_enum == WeaponEnum.Drone_MachineGun then
        -- Drone hit local player
        if args.entity_type == "LocalPlayer" then

            local bone = LocalPlayer:GetClosestBone(args.hit_position)
            local damage = WeaponDamage:CalculatePlayerDamage(LocalPlayer, args.weapon_enum, bone, args.distance_travelled, nil, args.damage_mod) * 100

            if damage == 0 then return end

            Network:Send(var("HitDetection/DetectDroneHitLocalPlayer"):get(), {
                weapon_enum = args.weapon_enum,
                damage_mod = args.damage_mod,
                bone_enum = bone,
                distance_travelled = args.distance_travelled,
                hit_position = args.hit_position,
                token = TOKEN:get()
            })

        elseif args.entity_type == "Vehicle" then
            -- Drone hits a vehicle

            local damage = WeaponDamage:CalculateVehicleDamage(args.entity, args.weapon_enum, args.distance_travelled) * 100

            if damage == 0 then return end

            local my_dist = LocalPlayer:GetPosition():Distance(args.hit_position)

            for p in Client:GetStreamedPlayers() do
                if p:GetPosition():Distance(args.hit_position) < my_dist then return end
            end
        
            Network:Send(var("HitDetection/DetectVehicleDroneHit"):get(), {
                vehicle_id = args.entity:GetId(),
                weapon_enum = args.weapon_enum,
                distance_travelled = args.distance_travelled,
                token = TOKEN:get()
            })
        end

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
            cVehicleWeaponManager:IsValidVehicleWeaponAction(Action.VehicleFireRight)
        
            local bullet_config = cWeaponBulletConfig:GetByWeaponEnum(weapon_enum)
        
            if not bullet_config then return end
    
            if bullet_config.indicator then
                cVehicleWeaponManager:DrawBloom(math.min(50, self.bloom * 5), Color(255,255,255,100))
                return
            end

        end

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
