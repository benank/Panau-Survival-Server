class 'sHitDetection'

function sHitDetection:__init()

    Network:Subscribe("HitDetectionBulletHit", self, self.BulletHit)
    Network:Subscribe("HitDetectionExplosionHit", self, self.ExplosionHit)
end

function sHitDetection:ExplosionHit(args, player)

    if not IsValid(args.attacker) then return end

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end

    local percent = 1

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
    player:Damage(damage / 100, DamageEntity.Bullet, args.attacker)

    print(string.format("%s shot %s for %s damage [%s]",
    args.attacker:GetName(), player:GetName(), tostring(damage), tostring(weapon.id)))

    -- If their health doesn't change after being shot
    --[[Timer.SetTimeout(2000, function()
        if IsValid(player) and player:GetHealth() >= old_hp and damage > 0 then
            print(player:GetName() .. " kicked for health hacks")
            player:Kick("Health hacks")
        end
    end)]]

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
    player:Damage(damage / 100, DamageEntity.Bullet, args.attacker)

    print(string.format("%s shot %s for %s damage [%s]",
    args.attacker:GetName(), player:GetName(), tostring(damage), tostring(weapon.id)))

    -- If their health doesn't change after being shot
    --[[Timer.SetTimeout(200, function()
        if IsValid(player) and player:GetHealth() >= old_hp and damage > 0 then
            print(player:GetName() .. " kicked for health hacks")
            player:Kick("Health hacks")
        end
    end)]]

end

function sHitDetection:GetArmorMod(player, hit_type, damage, original_damage)

    local equipped_items = player:GetValue("EquippedItems")

    for armor_name, mods in pairs(ArmorModifiers) do
        if equipped_items[armor_name] and ArmorModifiers[armor_name][hit_type] > 0 then

            damage = damage * (1 - ArmorModifiers[armor_name][hit_type])
            Events:Fire("HitDetection/ArmorDamaged", {
                player = player,
                armor_name = armor_name,
                damage = original_damage
            })

        end
    end

    return damage

end

sHitDetection = sHitDetection()