class 'sHitDetection'

function sHitDetection:__init()

    Network:Subscribe("HitDetectionSyncHit", self, self.SyncHit)
    Network:Subscribe("HitDetectionSyncExplosion", self, self.HitDetectionSyncExplosion)

    Events:Subscribe("HitDetection/PlayerInToxicArea", self, self.PlayerInsideToxicArea)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
end

function sHitDetection:PlayerDeath(args)
    args.player:SetNetworkValue("OnFire", false)
end

function sHitDetection:PlayerInsideToxicArea(args)
    args.player:Damage(ToxicDamagePerSecond, DamageEntity.Toxic, args.attacker)

    print(string.format("%s was damaged by toxic gas for %s damage [Source: %s] [%s]",
        args.player:GetName(), 
        tostring(ToxicDamagePerSecond), 
        IsValid(args.attacker) and tostring(args.attacker:GetSteamId()) or "Unknown", 
        args.type))
end

function sHitDetection:SecondTick()

    for p in Server:GetPlayers() do
        if p:GetValue("OnFire") and (p:GetPosition().y < 199.5 or p:GetValue("InSafezone")) then
            p:SetNetworkValue("OnFire", false)
        elseif p:GetValue("OnFire") then
            p:Damage(FireDamagePerSecond, DamageEntity.Fire, p:GetValue("FireAttacker"))

            print(string.format("%s was damaged by fire for %s damage [Source: %s] [%s]",
                p:GetName(), 
                tostring(FireDamagePerSecond), 
                IsValid(p:GetValue("FireAttacker")) and tostring(p:GetValue("FireAttacker"):GetSteamId()) or "Unknown", 
                "Molotov"))
        
        end
    end

end

function sHitDetection:HitDetectionSyncExplosion(args, player)
    
    if player:GetValue("InSafezone") then return end

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

    if args.in_fov then
        damage = self:GetArmorMod(player, hit_type, damage, original_damage)

        local old_hp = player:GetHealth()
        player:SetValue("LastHealth", old_hp)

        if IsValid(attacker) then
            player:Damage(damage / 100, DamageEntity.Explosion, attacker)
        else
            player:Damage(damage / 100, DamageEntity.Explosion)
        end
    end

    print(string.format("%s was exploded for %s damage [Source: %s] [%s]",
        player:GetName(), tostring(damage), tostring(args.attacker_id), tostring(args.type)))

    Events:Fire("HitDetection/PlayerExplosionItemHit", {
        player = player,
        damage = damage,
        type = args.type
    })

    if player:InVehicle() then
        player:GetVehicle():SetHealth(player:GetVehicle():GetHealth() - original_damage / explosive_data.damage * 0.5)
        player:GetVehicle():SetLinearVelocity(player:GetVehicle():GetLinearVelocity() + ((player:GetVehicle():GetPosition() - args.position):Normalized() * explosive_data.radius * explosive_data.knockback))
    end

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

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end

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

    print(string.format("%s shot %s for %s damage [%s]",
    args.attacker:GetName(), player:GetName(), tostring(damage), tostring(weapon.id)))

    Events:Fire("HitDetection/PlayerExplosionHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
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

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end

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

    print(string.format("%s shot %s for %s damage [%s]",
    args.attacker:GetName(), player:GetName(), tostring(damage), tostring(weapon.id)))

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
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

sHitDetection = sHitDetection()