class 'sHitDetection'

function sHitDetection:__init()

    self.last_damage_timeout = 15 -- 15 seconds to clear last damaged kill attribution

    Network:Subscribe("HitDetectionSyncHit", self, self.SyncHit)
    Network:Subscribe("HitDetectionSyncExplosion", self, self.HitDetectionSyncExplosion)

    Events:Subscribe("HitDetection/PlayerInToxicArea", self, self.PlayerInsideToxicArea)
    Events:Subscribe("HitDetection/PlayerSurvivalDamage", self, self.PlayerSurvivalDamage)

    Events:Subscribe("HitDetection/VehicleGuardActivate", self, self.VehicleGuardActivate)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
end

function sHitDetection:VehicleGuardActivate(args)

    local attacker = nil

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == args.attacker_id then
            attacker = p
            break
        end
    end

    if IsValid(attacker) then
        args.player:Damage(VehicleGuardDamage, DamageEntity.VehicleGuard, attacker)
    else
        args.player:Damage(VehicleGuardDamage, DamageEntity.VehicleGuard)
    end

    local msg = string.format("%s [%s] was damaged by vehicle guard for %s damage [Source: %s]",
        args.player:GetName(), 
        tostring(args.player:GetSteamId()),
        tostring(VehicleGuardDamage), 
        args.attacker_id, 
        DamageEntityNames[DamageEntity.VehicleGuard])

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })

    self:SetPlayerLastDamaged(args.player, DamageEntityNames[DamageEntity.VehicleGuard], args.attacker_id)

end

function sHitDetection:PlayerSurvivalDamage(args)

    if args.player:GetHealth() <= 0 then return end
    if args.player:GetValue("InSafezone") then return end
    
    args.player:Damage(args.amount, args.type)

    local msg = string.format("%s [%s] was damaged by survival for %s damage [%s]",
        args.player:GetName(), 
        tostring(args.player:GetSteamId()),
        tostring(args.amount), 
        DamageEntityNames[args.type])

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })
end

function sHitDetection:PlayerDeath(args)
    args.player:SetNetworkValue("OnFire", false)

    local last_damaged = args.player:GetValue("LastDamaged")

    if last_damaged and last_damaged.timer:GetSeconds() < self.last_damage_timeout then
        -- Kill attribution
        local query = SQL:Query("SELECT name FROM player_names WHERE steam_id = (?) LIMIT 1")
        query:Bind(1, last_damaged.steam_id)
        local killer_name = query:Execute()

        if killer_name and killer_name[1] and killer_name[1].name then
            killer_name = killer_name[1].name
        else
            killer_name = "???"
        end

        local msg = string.format("%s [%s] was killed by %s [%s] [%s]", 
            args.player:GetName(),
            tostring(args.player:GetSteamId()),
            killer_name,
            last_damaged.steam_id,
            DamageEntityNames[args.reason])

        Chat:Send(args.player, string.format("You were killed by %s [%s]", 
            killer_name, last_damaged.damage_type), Color.Red)
        
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = last_damaged.steam_id,
            message = string.format("You killed %s [%s]", args.player:GetName(), last_damaged.damage_type),
            color = Color.Red
        })

        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })

    else
        -- Player died on their own without anyone else, like drowning or falling from too high

        local msg = string.format("%s [%s] died [%s]", 
            args.player:GetName(),
            tostring(args.player:GetSteamId()),
            DamageEntityNames[args.reason])

        Chat:Send(args.player, string.format("You died [Reason: %s]", DamageEntityNames[args.reason]), Color.Red)
        
        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })
    end

    args.player:SetValue("LastDamaged", nil)
end

function sHitDetection:PlayerInsideToxicArea(args)
    if args.player:GetHealth() <= 0 then return end
    if args.player:GetValue("Loading") then return end

    local attacker = nil

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == args.attacker_id then
            attacker = p
            break
        end
    end

    if IsValid(attacker) then
        args.player:Damage(ToxicDamagePerSecond, DamageEntity.ToxicGrenade, attacker)
    else
        args.player:Damage(ToxicDamagePerSecond, DamageEntity.ToxicGrenade)
    end

    local msg = string.format("%s [%s] was damaged by toxic gas for %s damage [Source: %s] [%s]",
        args.player:GetName(), 
        tostring(args.player:GetSteamId()),
        tostring(ToxicDamagePerSecond), 
        args.attacker_id, 
        DamageEntityNames[DamageEntity.ToxicGrenade])

    self:SetPlayerLastDamaged(args.player, DamageEntityNames[DamageEntity.ToxicGrenade], args.attacker_id)

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })

end

function sHitDetection:SecondTick()

    for p in Server:GetPlayers() do
        if p:GetValue("OnFire") and (p:GetPosition().y < 199.5 or p:GetValue("InSafezone")) then
            p:SetNetworkValue("OnFire", false)
        elseif p:GetValue("OnFire") and p:GetHealth() >= 0 then

            local attacker = nil
            local attacker_id = p:GetValue("FireAttackerId")

            for p in Server:GetPlayers() do
                if tostring(p:GetSteamId()) == attacker_id then
                    attacker = p
                    break
                end
            end

            if IsValid(attacker) then
                p:Damage(FireDamagePerSecond, DamageEntity.Molotov, attacker)
            else
                p:Damage(FireDamagePerSecond, DamageEntity.Molotov)
            end

            local msg = string.format("%s [%s] was damaged by fire for %s damage [Source: %s] [%s]",
                p:GetName(), 
                tostring(p:GetSteamId()),
                tostring(FireDamagePerSecond), 
                attacker_id, 
                DamageEntityNames[DamageEntity.Molotov])
        
            self:SetPlayerLastDamaged(p, DamageEntityNames[DamageEntity.Molotov], attacker_id)

            print(msg)
            Events:Fire("Discord", {
                channel = "Hitdetection",
                content = msg
            })
        end
    end

end

function sHitDetection:HitDetectionSyncExplosion(args, player)
    
    if player:GetValue("InSafezone") then return end
    if player:GetHealth() <= 0 then return end
    if player:GetValue("Loading") then return end

    local explosive_data = ExplosiveBaseDamage[args.type]

    if not explosive_data then return end

    local dist = args.position:Distance(args.local_position)
    dist = math.min(explosive_data.radius / 2, math.max(0, dist / 2))
    local percent_modifier = math.max(0, 1 - (dist / (explosive_data.radius / 2)))

    if percent_modifier == 0 then return end

    local hit_type = WeaponHitType.Explosive
    local original_damage = explosive_data.damage * percent_modifier
    local damage = original_damage

    local attacker = nil

    if args.attacker_id then
        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == args.attacker_id then
                attacker = p
                break
            end
        end
    end

    if not args.in_fov then return end
    
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    local old_hp = player:GetHealth()
    player:SetValue("LastHealth", old_hp)

    if IsValid(attacker) then
        player:Damage(damage / 100, args.type, attacker)
    else
        player:Damage(damage / 100, args.type)
    end

    local msg = string.format("%s [%s] was exploded for %s damage [Source: %s] [%s]",
        player:GetName(), tostring(player:GetSteamId()), tostring(damage), tostring(args.attacker_id), DamageEntityNames[args.type])

    Events:Fire("HitDetection/PlayerExplosionItemHit", {
        player = player,
        damage = damage,
        type = args.type
    })

    if player:InVehicle() then
        player:GetVehicle():SetHealth(player:GetVehicle():GetHealth() - original_damage / explosive_data.damage * 0.5)
        player:GetVehicle():SetLinearVelocity(player:GetVehicle():GetLinearVelocity() + ((player:GetVehicle():GetPosition() - args.position):Normalized() * explosive_data.radius * explosive_data.knockback))
    end

    if args.attacker_id then
        self:SetPlayerLastDamaged(player, DamageEntityNames[args.type], args.attacker_id)
    end

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })

end

function sHitDetection:SyncHit(args, player)

    for _, v in pairs(args.pending) do

        if v.type == WeaponHitType.Explosive then
            self:ExplosionHit(v, player)
        else
            self:BulletHit(v, player)
        end

    end

end

function sHitDetection:ExplosionHit(args, player)

    if not IsValid(args.attacker) then return end
    if player:GetValue("Loading") then return end

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end
    if player:GetHealth() <= 0 then return end

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

    local old_hp = player:GetHealth()
    player:SetValue("LastHealth", old_hp)
    player:Damage(damage / 100, DamageEntity.Explosion, args.attacker)

    local msg = string.format("%s [%s] shot %s [%s] for %s damage [%s]",
        args.attacker:GetName(), 
        tostring(args.attacker:GetSteamId()),
        player:GetName(), 
        tostring(player:GetSteamId()),
        tostring(damage), 
        tostring(GetWeaponName(weapon.id)))

    Events:Fire("HitDetection/PlayerExplosionHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
    })

    self:SetPlayerLastDamaged(player, GetWeaponName(weapon.id), tostring(args.attacker:GetSteamId()))

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })
    --self:CheckHealth(player, damage)

end

function sHitDetection:CheckHealth(player, damage)

    local timeout = player:GetPing() * 2 + 1000
    -- If their health doesn't change after being shot

    Timer.SetTimeout(timeout, function()
        if not IsValid(player) then return end
        if IsValid(player) and player:GetHealth() >= player:GetValue("LastHealth") and damage > 0 and player:GetHealth() > 0 then
            Events:Fire("KickPlayer", {
                player = player,
                reason = string.format("Health hacks. Current health %s, last known health: %s", 
                    tostring(player:GetHealth()), tostring(player:GetValue("LastHealth"))),
                p_reason = "Health hacks"
            })
        end
    end)

end

function sHitDetection:BulletHit(args, player)
    if not args.bone or not BoneModifiers[args.bone.name] then return end
    if not IsValid(args.attacker) then return end
    if player:GetValue("Loading") then return end

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end
    if player:GetHealth() <= 0 then return end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end
    
    if not WeaponBaseDamage[weapon.id] then return end

    local hit_type = BoneModifiers[args.bone.name].type
    local original_damage = WeaponBaseDamage[weapon.id] * BoneModifiers[args.bone.name].mod
    local damage = original_damage
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    local old_hp = player:GetHealth()
    player:SetValue("LastHealth", old_hp)
    player:Damage(damage / 100, DamageEntity.Bullet, args.attacker)

    local msg = string.format("%s [%s] shot %s [%s] for %s damage [%s]",
        args.attacker:GetName(), 
        tostring(args.attacker:GetSteamId()),
        player:GetName(), 
        tostring(player:GetSteamId()),
        tostring(damage), 
        tostring(GetWeaponName(weapon.id)))

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
    })

    self:SetPlayerLastDamaged(player, GetWeaponName(weapon.id), tostring(args.attacker:GetSteamId()))

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })
    -- If their health doesn't change after being shot
    --self:CheckHealth(player, damage)

end

function sHitDetection:GetArmorMod(player, hit_type, damage, original_damage)

    local equipped_items = player:GetValue("EquippedItems")

    for armor_name, mods in pairs(ArmorModifiers) do
        if equipped_items[armor_name] and ArmorModifiers[armor_name][hit_type] > 0 then

            damage = damage * (1 - ArmorModifiers[armor_name][hit_type])

            -- If the armor prevented some damage, then modify its durability
            if ArmorModifiers[armor_name][hit_type] > 0 then
                Events:Fire("HitDetection/ArmorDamaged", {
                    player = player,
                    armor_name = armor_name,
                    damage_diff = original_damage - original_damage * (1 - ArmorModifiers[armor_name][hit_type])
                })
            end

        end
    end

    return damage

end

function sHitDetection:SetPlayerLastDamaged(player, damage_type, steam_id)
    player:SetValue("LastDamaged", {
        damage_type = damage_type, -- Name of damage type
        steam_id = steam_id,
        timer = Timer()
    })
end

sHitDetection = sHitDetection()