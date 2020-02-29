class 'sHitDetection'

function sHitDetection:__init()

    Network:Subscribe("HitDetectionBulletHit", self, self.BulletHit)
end

function sHitDetection:BulletHit(args, player)
    if not args.bone or not BoneModifiers[args.bone.name] then return end
    if not IsValid(args.attacker) then return end

    if args.attacker:GetValue("InSafezone") or player:GetValue("InSafezone") then return end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end
    
    local hit_type = BoneModifiers[args.bone.name].type
    local original_damage = WeaponBaseDamage[weapon.id] * BoneModifiers[args.bone.name].mod
    local damage = original_damage

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

    local old_hp = player:GetHealth()
    player:Damage(damage / 100, DamageEntity.Bullet, args.attacker)

    print(string.format("%s shot %s for %s damage [%s]",
    args.attacker:GetName(), player:GetName(), tostring(damage), tostring(weapon.id)))

    -- If their health doesn't change after being shot
    Timer.SetTimeout(200, function()
        if IsValid(player) and player:GetHealth() >= old_hp and damage > 0 then
            print(player:GetName() .. " kicked for health hacks")
            player:Kick("Health hacks")
        end
    end)

end

sHitDetection = sHitDetection()