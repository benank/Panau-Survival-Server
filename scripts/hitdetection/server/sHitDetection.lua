class 'sHitDetection'

function sHitDetection:__init()

    self.PING_LIMIT = 500 -- No damage if you are above 500 ping
    self.health_check_threshold = 0.15
    self.health_strikes_max = 5

    self.pending_hits = {}
    self.last_damage_timeout = 15 -- 15 seconds to clear last damaged kill attribution

    self.players = {}

    self.pending_armor_aggregation = {}

    self.combat_log_time = 20
    self.players_in_combat = {}

    self:CheckPendingHits()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

    Network:Subscribe("HitDetection/DetectPlayerHit", self, self.DetectPlayerHit)
    Network:Subscribe("HitDetection/DetectVehicleHit", self, self.DetectVehicleHit)
    Network:Subscribe("HitDetection/DetectVehicleDroneHit", self, self.DetectVehicleDroneHit)
    Network:Subscribe("HitDetection/DetectDroneHit", self, self.DetectDroneHit)
    Network:Subscribe("HitDetection/DetectPlayerSplashHit", self, self.DetectPlayerSplashHit)
    Network:Subscribe("HitDetection/DetectVehicleSplashHit", self, self.DetectVehicleSplashHit)
    Network:Subscribe("HitDetectionSyncExplosion", self, self.HitDetectionSyncExplosion)
    Network:Subscribe("HitDetection/VehicleExplosionHit", self, self.VehicleExplosionHit)
    Network:Subscribe("HitDetection/DetectDroneHitLocalPlayer", self, self.DetectDroneHitLocalPlayer)
    Network:Subscribe("HitDetectionSyncExplosionDrone", self, self.HitDetectionSyncExplosionDrone)
    Network:Subscribe("HitDetection/DetectDroneSplashHit", self, self.DetectDroneSplashHit)
    
    Events:Subscribe("drones/DroneDestroyed", self, self.DroneDestroyed)

    Events:Subscribe("HitDetection/PlayerInToxicArea", self, self.PlayerInsideToxicArea)
    Events:Subscribe("HitDetection/PlayerSurvivalDamage", self, self.PlayerSurvivalDamage)

    Events:Subscribe("HitDetection/VehicleGuardActivate", self, self.VehicleGuardActivate)
    Events:Subscribe("HitDetection/WarpGrenade", self, self.WarpGrenade)

    Network:Subscribe("HitDetection/MeleeGrappleHit", self, self.MeleeGrappleHit)
    Network:Subscribe("HitDetection/MeleeStandingKickHit", self, self.MeleeStandingKickHit)
    Network:Subscribe("HitDetection/MeleeSlidingKickHit", self, self.MeleeSlidingKickHit)

    Events:Subscribe("Hitdetection/AdminKill", self, self.AdminKill)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)

    Events:Subscribe("LoadStatus", self, self.LoadStatus)

    Network:Subscribe("Hitdetection/Respawn", self, self.Respawn)

end

function sHitDetection:LoadStatus(args)
    if self.players_in_combat[tostring(args.player:GetSteamId())] then

        args.player:SetValue("FirstSpawn", true)
        self:ApplyDamage({
            player = args.player,
            damage = 999,
            source = DamageEntity.CombatLog,
            attacker_id = self.players_in_combat[tostring(args.player:GetSteamId())].attacker_id
        })

        self.players_in_combat[tostring(args.player:GetSteamId())] = nil

    end
end

function sHitDetection:ClientModuleLoad(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
    args.player:SetValue("HealthStrikes", 0)
end

function sHitDetection:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function sHitDetection:ApplyDamage(args)

    if args.player:GetValue("Loading") then return end
    if args.player:GetValue("Invincible") then return end
    if args.player:GetValue("InSafezone") 
    and args.source ~= DamageEntity.Suicide 
    and args.source ~= DamageEntity.AdminKill
    and args.source ~= DamageEntity.CombatLog then return end

    local old_hp = args.player:GetHealth()

    if old_hp <= 0 then return end

    attacker = args.attacker_id and self.players[args.attacker_id] or args.attacker

    local msg = ""
    
    if not IsValid(attacker) and not args.attacker_id then
        args.player:Damage(args.damage, args.source)

        msg = string.format("%s [%s] damaged by %s for %.2f damage",
            args.player:GetName(), 
            tostring(args.player:GetSteamId()),
            DamageEntityNames[args.source],
            args.damage * 100)

    elseif not IsValid(attacker) and args.attacker_id then

        args.player:Damage(args.damage, args.source)
            
        msg = string.format("%s [%s] damaged by %s from [%s] for %.2f damage",
            args.player:GetName(), 
            tostring(args.player:GetSteamId()),
            DamageEntityNames[args.source],
            args.attacker_id,
            args.damage * 100)

        self:SetPlayerLastDamaged(args.player, DamageEntityNames[args.source], args.attacker_id)

    else

        args.player:Damage(args.damage, args.source, attacker)
            
        msg = string.format("%s [%s] damaged by %s from %s [%s] for %.2f damage",
            args.player:GetName(), 
            tostring(args.player:GetSteamId()),
            DamageEntityNames[args.source],
            attacker:GetName(),
            tostring(attacker:GetSteamId()),
            args.damage * 100)

        if args.source == DamageEntity.Explosion or args.source == DamageEntity.Bullet then
            -- Append weapon name too

            msg = msg .. string.format(" [Weapon: %s]", WeaponEnum:GetDescription(args.weapon_enum))

        end

        if attacker:InVehicle() then

            msg = msg .. string.format(" [Vehicle: %s]", attacker:GetVehicle():GetName())

        end

        if args.damage > 0 then
            self:SetPlayerLastDamaged(args.player, DamageEntityNames[args.source], tostring(attacker:GetSteamId()), args.weapon_enum)
        end

    end

    args.player:SetNetworkValue("InCombat", true)
    self.players_in_combat[tostring(args.player:GetSteamId())] = {time = Server:GetElapsedSeconds(), attacker_id = args.attacker_id}

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })

end

function sHitDetection:DroneDestroyed(args)
    if not IsValid(args.player) then return end
    Network:Send(args.player, "HitDetection/DealDamage", {red = true})
end

function sHitDetection:MeleeGrappleHit(args, player)

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    if not args.victim_id then return end

    local victim = self.players[args.victim_id]
    if not IsValid(victim) then return end

    if victim:GetPosition():Distance(player:GetPosition()) > 7 then return end

    self:ApplyDamage({
        player = victim, 
        damage = WeaponDamage:CalculateMeleeDamage(victim, DamageEntity.MeleeGrapple), 
        source = DamageEntity.MeleeGrapple, 
        attacker_id = tostring(player:GetSteamId())
    })

end

function sHitDetection:MeleeStandingKickHit(args, player)

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    if not args.victim_id then return end

    local victim = self.players[args.victim_id]
    if not IsValid(victim) then return end

    if victim:GetPosition():Distance(player:GetPosition()) > 7 then return end

    self:ApplyDamage({
        player = victim, 
        damage = WeaponDamage:CalculateMeleeDamage(victim, DamageEntity.MeleeKick), 
        source = DamageEntity.MeleeKick, 
        attacker_id = tostring(player:GetSteamId())
    })

end

function sHitDetection:MeleeSlidingKickHit(args, player)

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    if not args.victim_id then return end

    local victim = self.players[args.victim_id]
    if not IsValid(victim) then return end

    if victim:GetPosition():Distance(player:GetPosition()) > 7 then return end

    self:ApplyDamage({
        player = victim, 
        damage = WeaponDamage:CalculateMeleeDamage(victim, DamageEntity.MeleeSlidingKick), 
        source = DamageEntity.MeleeSlidingKick, 
        attacker_id = tostring(player:GetSteamId())
    })

    Network:Send(victim, "HitDetection/KnockdownEffect", 
        {source = player:GetPosition(), amount = WeaponDamage.MeleeDamage[DamageEntity.MeleeSlidingKick].knockback})

end

function sHitDetection:AdminKill(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage({
        player = args.player,
        damage = 9999, 
        source = DamageEntity.AdminKill,
        attacker_id = tostring(args.attacker:GetSteamId())
    })

end

function sHitDetection:Respawn(args, player)

    if player:GetHealth() <= 0 then return end
    if player:GetValue("dead") then return end

    if player:GetValue("Loading") then return end

    if player:InVehicle() then
        Chat:Send(player, "You must exit the vehicle to use this command.", Color.Red)
        return
    end

    local survival = player:GetValue("Survival")

    if not survival then return end

    if survival.hunger <= 10 or survival.thirst <= 20 then
        Chat:Send(player, "You cannot use this command right now.", Color.Red)
        return
    end

    self:ApplyDamage({
        player = player, 
        damage = WeaponDamage.SuicideDamage, 
        source = DamageEntity.Suicide
    })

    local last_damaged = player:GetValue("LastDamaged")

    if last_damaged then
        if Server:GetElapsedSeconds() - last_damaged.timer > self.last_damage_timeout then
            player:SetValue("Suicided", true)
        else
            player:SetValue("Suicided", nil)
        end
    else
        player:SetValue("Suicided", true)
    end

end

function sHitDetection:CheckPendingHits()

    Timer.SetInterval(500, function()
        if count_table(self.pending_armor_aggregation) > 0 then

            for steam_id, data in pairs(self.pending_armor_aggregation) do
                for armor_name, hit_data in pairs(data) do
                    Events:Fire("HitDetection/ArmorDamaged", hit_data)
                    self.pending_armor_aggregation[steam_id][armor_name] = nil
                end

                if count_table(self.pending_armor_aggregation[steam_id]) == 0 then
                    self.pending_armor_aggregation[steam_id] = nil
                end
            end
        end
    end)

end

function sHitDetection:WarpGrenade(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage({
        player = args.player, 
        damage = WeaponDamage.WarpGrenadeDamage, 
        source = DamageEntity.WarpGrenade
    })

end

function sHitDetection:VehicleGuardActivate(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage({
        player = args.player, 
        damage = WeaponDamage.VehicleGuardDamage, 
        source = DamageEntity.VehicleGuard, 
        attacker_id = args.attacker_id
    })

end

function sHitDetection:PlayerSurvivalDamage(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage({
        player = args.player, 
        damage = args.amount, 
        source = args.type
    })
    
end

function sHitDetection:PlayerDeath(args)

    args.player:SetNetworkValue("OnFire", false)

    -- TODO: check if player's vehicle was damaged and apply kill attribution to killer

    local last_damaged = args.player:GetValue("LastDamaged")

    if last_damaged and Server:GetElapsedSeconds() - last_damaged.timer < self.last_damage_timeout then
        -- Kill attribution
        local query = SQL:Query("SELECT name FROM player_names WHERE steam_id = (?) LIMIT 1")
        query:Bind(1, last_damaged.steam_id)
        local killer_name = query:Execute()

        if killer_name and killer_name[1] and killer_name[1].name then
            killer_name = killer_name[1].name
        else
            killer_name = "???"
        end

        -- TODO: add weapon name and vehicle as well

        local msg = string.format("%s [%s] was killed by %s [%s] [%s]", 
            args.player:GetName(),
            tostring(args.player:GetSteamId()),
            killer_name,
            last_damaged.steam_id,
            DamageEntityNames[args.reason])

        local additional_info = ""

        if last_damaged.weapon_enum then
            additional_info = additional_info .. string.format(" [Weapon: %s]", WeaponEnum:GetDescription(last_damaged.weapon_enum))
        end

        local killer = self.players[last_damaged.steam_id]

        if IsValid(killer) then
            Network:Send(killer, "HitDetection/DealDamage", {red = true})

            if killer:InVehicle() then
                additional_info = additional_info .. string.format(" [Vehicle: %s]", killer:GetVehicle():GetName())
            end
        end

        msg = msg .. additional_info

        Chat:Send(args.player, string.format("You were killed by %s [%s]%s", 
            killer_name, last_damaged.damage_type, additional_info), Color.Red)
        
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = last_damaged.steam_id,
            message = string.format("You killed %s [%s]%s %s", 
                args.player:GetName(), last_damaged.damage_type, additional_info, WorldToMapString(args.player:GetPosition())),
            color = Color.Red
        })

        msg = msg .. " " .. WorldToMapString(args.player:GetPosition())

        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })

    else
        -- Player died on their own without anyone else, like drowning or falling from too high

        local msg = ""
        if args.reason == DamageEntity.DroneMachineGun then

            msg = string.format("%s [%s] was killed by a drone. [%s]", 
                args.player:GetName(),
                tostring(args.player:GetSteamId()),
                DamageEntityNames[args.reason])

            Chat:Send(args.player, string.format("You were killed by a drone. [%s]", DamageEntityNames[args.reason]), Color.Red)

        else

            msg = string.format("%s [%s] died [%s]", 
                args.player:GetName(),
                tostring(args.player:GetSteamId()),
                DamageEntityNames[args.reason])

            Chat:Send(args.player, string.format("You died [Reason: %s]", DamageEntityNames[args.reason]), Color.Red)

        end
            
        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })
    end

    if not args.player:GetValue("Suicided") and not args.player:GetValue("Invisible") and not args.player:GetValue("Invincible") then
        Events:Fire("PlayerKilled", {player = args.player, killer = last_damaged and last_damaged.steam_id, reason = args.reason})
    end

    args.player:SetNetworkValue("InCombat", false)
    self.players_in_combat[tostring(args.player:GetSteamId())] = nil

    args.player:SetValue("LastDamaged", nil)
end

function sHitDetection:PlayerInsideToxicArea(args)
    
    if not IsValid(args.player) then return end

    self:ApplyDamage({
        player = args.player, 
        damage = WeaponDamage.ToxicDamagePerSecond, 
        source = DamageEntity.ToxicGrenade, 
        attacker_id = args.attacker_id
    })

end

function sHitDetection:SecondTick()
    for p in Server:GetPlayers() do
        if IsValid(p) and p:GetValue("OnFire") and 
        ( p:GetPosition().y < 199.5 or p:GetValue("InSafezone") 
            or Server:GetElapsedSeconds() - p:GetValue("OnFireTime") >= WeaponDamage.FireEffectTime
            or p:GetHealth() <= 0 ) then

            p:SetNetworkValue("OnFire", false)

        elseif IsValid(p) and p:GetValue("OnFire") then

            local attacker_id = p:GetValue("FireAttackerId")

            self:ApplyDamage({
                player = p, 
                damage = WeaponDamage.FireDamagePerSecond, 
                source = DamageEntity.Molotov, 
                attacker_id = attacker_id
            })

        end

        if IsValid(p) and p:GetValue("InCombat") and self.players_in_combat[tostring(p:GetSteamId())] then
            local combat_time = self.players_in_combat[tostring(p:GetSteamId())].time

            if Server:GetElapsedSeconds() - combat_time >= self.combat_log_time then
                p:SetNetworkValue("InCombat", false)
                self.players_in_combat[tostring(p:GetSteamId())] = nil
            end
        end
    end

end

function sHitDetection:VehicleExplosionHit(args, player)

    if not IsValid(player) then return end

    assert(args.hit_vehicles and count_table(args.hit_vehicles) > 0, "hit_vehicles is invalid")
    assert(args.type, "type is invalid")
    assert(args.position, "position is invalid")
    assert(args.attacker_id, "attacker_id is invalid")

    if not self:PlayerCanApplyDamage(player, tostring(args.token)) then return end

    local explosive_data = WeaponDamage.ExplosiveBaseDamage[args.type]
    if not explosive_data then return end

    for vehicle_id, data in pairs(args.hit_vehicles) do

        local sub
        sub = Events:Subscribe("GetPlayerPerksById" .. tostring(args.attacker_id), function(perks)

            local v = Vehicle.GetById(vehicle_id)

            if not IsValid(v) then return end
            
            local perk_mods = {[1] = 1, [2] = 1}
            local damage_perks = WeaponDamage.ExplosiveDamagePerks[args.type]
    
            if damage_perks and perks then
    
                for perk_id, perk_mod_data in pairs(damage_perks) do
                    local choice = perks.unlocked_perks[perk_id]
                    if perk_mod_data[choice] then
                        perk_mods[choice] = math.max(perk_mods[choice], perk_mod_data[choice])
                    end
                end

            end

            local radius = explosive_data.radius
            radius = radius * perk_mods[2]

            local v_pos = v:GetPosition()
            local dist = data.dist -- Use clientside distance in case of desync
            local percent_modifier = math.max(0, 1 - dist / radius)

            if percent_modifier > 0 then

                local hit_type = WeaponHitType.Explosive
                local original_damage = explosive_data.damage * percent_modifier
                local damage = original_damage

                if not data.in_fov then
                    damage = damage * WeaponDamage.FOVDamageModifierVehicle
                end

                local armor = WeaponDamage.vehicle_armors[v:GetModelId()] or 1
                damage = damage * explosive_data.v_mod * armor * perk_mods[1]

                v:SetHealth(v:GetHealth() - damage / 100)

                local v_data = v:GetValue("VehicleData")

                if not v_data then return end

                local msg = string.format("%s [ID: %s] [Owner: %s] was damaged by %s from [%s] for %.2f damage", 
                    v:GetName(), tostring(v_data.vehicle_id), tostring(v_data.owner_steamid), 
                    DamageEntityNames[args.type], args.attacker_id, damage)

                Events:Fire("Discord", {
                    channel = "Hitdetection",
                    content = msg
                })

                v:SetLinearVelocity(v:GetLinearVelocity() + (data.hit_dir * radius * explosive_data.knockback * (armor * 0.1)))

                sub = Events:Unsubscribe(sub)

            end

        end)

        Events:Fire("GetPlayerPerksById", {steam_id = args.attacker_id})

    end
    
end

-- Player hits a drone with an explosive
function sHitDetection:HitDetectionSyncExplosionDrone(args, player)
    
    if not IsValid(player) then return end

    local explosive_data = WeaponDamage.ExplosiveBaseDamage[args.type]

    if not explosive_data then return end

    local sub
    sub = Events:Subscribe("GetPlayerPerksById" .. tostring(args.attacker_id), function(perks)

        local perk_mods = {[1] = 1, [2] = 1}
        local damage_perks = WeaponDamage.ExplosiveDamagePerks[args.type]

        if damage_perks and perks then

            for perk_id, perk_mod_data in pairs(damage_perks) do
                local choice = perks.unlocked_perks[perk_id]
                if perk_mod_data[choice] then
                    perk_mods[choice] = math.max(perk_mods[choice], perk_mod_data[choice])
                end
            end

        end

        local radius = explosive_data.radius
        radius = radius * perk_mods[2]

        local dist = args.position:Distance(args.drone_position)
        local percent_modifier = math.max(0, 1 - dist / radius)

        if percent_modifier == 0 then return end

        local hit_type = WeaponHitType.Explosive
        local original_damage = explosive_data.damage * percent_modifier
        local damage = original_damage

        if not args.in_fov then
            damage = damage * WeaponDamage.FOVDamageModifier
        end

        damage = damage * perk_mods[1]

        Events:Fire("HitDetection/DroneDamaged", {
            player = self.players[args.attacker_id],
            drone_id = args.drone_id,
            damage = damage,
            type = args.type
        })

        sub = Events:Unsubscribe(sub)

    end)

    Events:Fire("GetPlayerPerksById", {steam_id = args.attacker_id})
    
end

function sHitDetection:HitDetectionSyncExplosion(args, player)
    
    if not IsValid(player) then return end

    local explosive_data = WeaponDamage.ExplosiveBaseDamage[args.type]

    if not explosive_data then return end

    local sub
    sub = Events:Subscribe("GetPlayerPerksById" .. tostring(args.attacker_id), function(perks)

        local perk_mods = {[1] = 1, [2] = 1}
        local damage_perks = WeaponDamage.ExplosiveDamagePerks[args.type]

        if damage_perks and perks then

            for perk_id, perk_mod_data in pairs(damage_perks) do
                local choice = perks.unlocked_perks[perk_id]
                if perk_mod_data[choice] then
                    perk_mods[choice] = math.max(perk_mods[choice], perk_mod_data[choice])
                end
            end

        end

        local radius = explosive_data.radius
        radius = radius * perk_mods[2]

        local dist = args.position:Distance(args.local_position)
        local percent_modifier = math.max(0, 1 - dist / radius)

        if percent_modifier == 0 then return end

        local hit_type = WeaponHitType.Explosive
        local original_damage = explosive_data.damage * percent_modifier
        local damage = original_damage

        if not args.in_fov and not player:InVehicle() then
            damage = damage * WeaponDamage.FOVDamageModifier
        elseif not args.in_fov and player:InVehicle() then
            damage = damage * WeaponDamage.FOVDamageModifierInVehicle
        end

        damage = damage * WeaponDamage:GetArmorMod(player, hit_type, damage, original_damage) * perk_mods[1]

        self:ApplyDamage({
            player = player, 
            damage = damage / 100, 
            source = args.type, 
            attacker_id = args.attacker_id
        })

        Events:Fire("HitDetection/PlayerExplosionItemHit", {
            player = player,
            damage = damage,
            type = args.type
        })

        sub = Events:Unsubscribe(sub)

    end)

    Events:Fire("GetPlayerPerksById", {steam_id = args.attacker_id})
    
end

function sHitDetection:ExplosionHit(args, player)

    --[[if not IsValid(player) then return end
    if not IsValid(args.attacker) then return end

    if args.attacker:GetValue("InSafezone") then return end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end

    local percent = 1
    if not args.damage then args.damage = 100 end

    if weapon.id == Weapon.GrenadeLauncher then
        percent = args.damage / 350
    elseif weapon.id == Weapon.RocketLauncher then
        percent = args.damage / 1000
    else
        percent = args.damage / 1000
    end

    percent = math.clamp(percent, 0, 1)

    if not WeaponBaseDamage[weapon.id] then return end
    
    local hit_type = WeaponHitType.Explosive
    local original_damage = WeaponBaseDamage[weapon.id] * percent
    local damage = original_damage
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    self:ApplyDamage(player, damage / 100, DamageEntity.Explosion, tostring(args.attacker:GetSteamId()))

    Events:Fire("HitDetection/PlayerExplosionHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
    })]]

end

-- Called by Player when Player is hit by a drone with a bullet
--[[
    args (in table):

        weapon_enum (integer): weapon enum of the weapon that the drone used
        bone_enum (integer): bone enum of the bone that was hit on the victim (the Player)
        distance_travelled (number): distance that the bullet travelled 
        damage_mod (number): damage mod that the drone has

]]
function sHitDetection:DetectDroneHitLocalPlayer(args, player)
    assert(IsValid(player), "player is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.bone_enum, "bone_enum is invalid")
    assert(args.distance_travelled and args.distance_travelled > 0, "distance_travelled is invalid")

    if not self:PlayerCanApplyDamage(player, tostring(args.token)) then return end
    args.damage_mod = math.max(1, args.damage_mod)

    if player:GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculatePlayerDamage(player, args.weapon_enum, args.bone_enum, args.distance_travelled, nil, args.damage_mod)

    self:ApplyDamage({
        player = player,
        damage = damage,
        source = DamageEntity.DroneMachineGun,
        weapon_enum = args.weapon_enum
    })

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = player,
        damage = damage
    })
    
end

-- Called by Player when Player hits another player with a bullet
--[[
    args (in table):

        victim_steam_id (string): steam id of the victim player
        weapon_enum (integer): weapon enum of the weapon that the Player used
        bone_enum (integer): bone enum of the bone that was hit on the victim
        distance_travelled (number): distance that the bullet travelled 

]]
function sHitDetection:DetectPlayerHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.victim_steam_id, "victim_steam_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.bone_enum, "bone_enum is invalid")
    assert(args.distance_travelled and args.distance_travelled > 0, "distance_travelled is invalid")

    if not self:PlayerCanApplyDamage(player, tostring(args.token)) then return end
    
    local victim = self.players[args.victim_steam_id]

    if not IsValid(victim) then return end

    if player:GetValue("InSafezone") then return end
    if victim:GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculatePlayerDamage(victim, args.weapon_enum, args.bone_enum, args.distance_travelled, player)

    self:ApplyDamage({
        player = victim,
        damage = damage,
        source = DamageEntity.Bullet,
        weapon_enum = args.weapon_enum, 
        attacker_id = tostring(player:GetSteamId()),
        attacker = player
    })

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = victim,
        attacker = player,
        damage = damage
    })

end

function sHitDetection:DetectDroneHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.drone_id, "drone_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.distance_travelled and args.distance_travelled > 0, "distance_travelled is invalid")

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    
    if player:GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculateDroneDamage(args.weapon_enum, args.distance_travelled, player)

    if damage <= 0 then return end

    Events:Fire("HitDetection/DroneDamaged", {
        player = player,
        drone_id = args.drone_id,
        damage = damage * 100,
        hit_position = args.hit_position
    })
    
end

function sHitDetection:DetectVehicleDroneHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.vehicle_id, "vehicle_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.distance_travelled and args.distance_travelled > 0, "distance_travelled is invalid")

    if not self:PlayerCanApplyDamage(player, args.token) then return end

    local vehicle = Vehicle.GetById(args.vehicle_id)

    if not IsValid(vehicle) then return end

    if vehicle:GetDriver() and vehicle:GetDriver():GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculateVehicleDamage(vehicle, args.weapon_enum, args.distance_travelled)

    if damage <= 0 then return end
    if vehicle:GetHealth() <= 0 then return end

    vehicle:SetHealth(math.max(0, vehicle:GetHealth() - damage))
end

function sHitDetection:DetectVehicleHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.vehicle_id, "vehicle_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.distance_travelled and args.distance_travelled > 0, "distance_travelled is invalid")

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    
    local vehicle = Vehicle.GetById(args.vehicle_id)

    if not IsValid(vehicle) then return end

    if player:GetValue("InSafezone") then return end
    if vehicle:GetDriver() and vehicle:GetDriver():GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculateVehicleDamage(vehicle, args.weapon_enum, args.distance_travelled, player)

    if damage <= 0 then return end
    if vehicle:GetHealth() <= 0 then return end

    vehicle:SetHealth(math.max(0, vehicle:GetHealth() - damage))
    
    if vehicle:GetDriver() then
        self:SetPlayerLastDamaged(vehicle:GetDriver(), DamageEntity.Bullet, tostring(player:GetSteamId()), args.weapon_enum)
    end

    vehicle:SetValue("LastDamaged", 
    {
        name = player:GetName(),
        weapon_name = WeaponEnum:GetDescription(args.weapon_enum)
    })

end

function sHitDetection:DetectDroneSplashHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.drone_id, "drone_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.damage_falloff and args.damage_falloff >= 0 and args.damage_falloff <= 1, "damage_falloff is invalid")

    if not self:PlayerCanApplyDamage(player, tostring(args.token)) then return end
    
    if player:GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculateDroneDamage(args.weapon_enum, args.distance_travelled, player) * args.damage_falloff

    Events:Fire("HitDetection/DroneDamaged", {
        player = player,
        drone_id = args.drone_id,
        damage = damage * 100,
        type = args.type
    })

end

function sHitDetection:DetectPlayerSplashHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.victim_steam_id, "victim_steam_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.damage_falloff and args.damage_falloff >= 0 and args.damage_falloff <= 1, "damage_falloff is invalid")

    if not self:PlayerCanApplyDamage(player, tostring(args.token)) then return end
    
    local victim = self.players[args.victim_steam_id]

    if not IsValid(victim) then return end

    if player:GetValue("InSafezone") then return end
    if victim:GetValue("InSafezone") then return end

    local damage = 
        WeaponDamage:CalculatePlayerDamage(victim, args.weapon_enum, BoneEnum.Spine1, args.distance_travelled, player) * args.damage_falloff

    self:ApplyDamage({
        player = victim,
        damage = damage,
        source = DamageEntity.Explosion,
        weapon_enum = args.weapon_enum, 
        attacker_id = tostring(player:GetSteamId()),
        attacker = player
    })

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = victim,
        attacker = player,
        damage = damage
    })


end

function sHitDetection:DetectVehicleSplashHit(args, player)

    assert(IsValid(player), "player is invalid")
    assert(args.vehicle_id, "victim_steam_id is invalid")
    assert(args.weapon_enum, "weapon_enum is invalid")
    assert(args.damage_falloff and args.damage_falloff >= 0 and args.damage_falloff <= 1, "damage_falloff is invalid")

    if not self:PlayerCanApplyDamage(player, args.token) then return end
    
    local vehicle = Vehicle.GetById(args.vehicle_id)

    if not IsValid(vehicle) then return end

    if player:GetValue("InSafezone") then return end
    if vehicle:GetDriver() and vehicle:GetDriver():GetValue("InSafezone") then return end

    local damage = WeaponDamage:CalculateVehicleDamage(vehicle, args.weapon_enum, 0, player) * args.damage_falloff

    if damage <= 0 then return end
    if vehicle:GetHealth() <= 0 then return end

    vehicle:SetHealth(math.max(0, vehicle:GetHealth() - damage))
    
    if vehicle:GetDriver() then
        self:SetPlayerLastDamaged(vehicle:GetDriver(), DamageEntity.Explosion, tostring(player:GetSteamId()), args.weapon_enum)
    end

    vehicle:SetValue("LastDamaged", 
    {
        name = player:GetName(),
        weapon_name = WeaponEnum:GetDescription(args.weapon_enum)
    })

end

function sHitDetection:SetPlayerLastDamaged(player, damage_type, steam_id, weapon_enum)
    player:SetValue("LastDamaged", {
        damage_type = damage_type, -- Name of damage type
        steam_id = steam_id,
        timer = Server:GetElapsedSeconds(),
        weapon_enum = weapon_enum
    })
end

-- Checks if a player can apply damage (valid token)
function sHitDetection:PlayerCanApplyDamage(player, token)
    return sTokens:PlayerTokenMatches(player, token) and player:GetPing() < self.PING_LIMIT
end

sHitDetection = sHitDetection()