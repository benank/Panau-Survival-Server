class "WeaponDamage"

function WeaponDamage:__init()

    self.pending_armor_aggregation = {}

    -- Start losing damage at distance_falloff / 2, and 0 damage past distance_falloff
    local falloff_func = function(distance, distance_falloff)
        return math.clamp(1 - (distance - distance_falloff / 2) / (distance_falloff / 2), 0, 1)
    end

    self.weapon_damages = {
        [WeaponEnum.MachineGun] =       {base = 0.07, distance_falloff = 500, falloff = falloff_func},
        [WeaponEnum.Handgun] =          {base = 0.05, distance_falloff = 150, falloff = falloff_func},
        [WeaponEnum.Assault] =          {base = 0.06, distance_falloff = 300, falloff = falloff_func},
        [WeaponEnum.BubbleGun] =        {base =-0.05, distance_falloff = 50,  falloff = falloff_func},
        [WeaponEnum.GrenadeLauncher] =  {base = 0.15, distance_falloff = 0,   falloff = function() return 0 end},
        [WeaponEnum.Revolver] =         {base = 0.10, distance_falloff = 300, falloff = falloff_func},
        [WeaponEnum.RocketLauncher] =   {base = 0.20, distance_falloff = 500, falloff = function() return 0 end},
        [WeaponEnum.SMG] =              {base = 0.06, distance_falloff = 100, falloff = falloff_func},
        [WeaponEnum.Sniper] =           {base = 0.90, distance_falloff = 200, falloff = 
            function(distance, distance_falloff) -- Sniper gains full power at 200+ meters away
                return math.clamp(distance / distance_falloff, 0, 1)
            end},
        [WeaponEnum.SawnOffShotgun] =   {base = 0.03, distance_falloff = 80, falloff = falloff_func},
        [WeaponEnum.Shotgun] =          {base = 0.04, distance_falloff = 80, falloff = falloff_func}
        -- TODO: vehicle weapons, minigun?
    }

    self.bone_damage_modifiers = {
        [BoneEnum.Head] = {modifier = 2.0, type = WeaponHitType.Headshot},
        [BoneEnum.Neck] = {modifier = 1.5, type = WeaponHitType.Headshot},
        [BoneEnum.Spine1] = {modifier = 1.0, type = WeaponHitType.Bodyshot},
        [BoneEnum.Spine2] = {modifier = 1.0, type = WeaponHitType.Bodyshot},
        [BoneEnum.Hips] = {modifier = 0.8, type = WeaponHitType.Bodyshot},
        [BoneEnum.LeftForeArm] = {modifier = 0.65, type = WeaponHitType.Bodyshot},
        [BoneEnum.RightForeArm] = {modifier = 0.65, type = WeaponHitType.Bodyshot},
        [BoneEnum.LeftArm] = {modifier = 0.75, type = WeaponHitType.Bodyshot},
        [BoneEnum.RightArm] = {modifier = 0.75, type = WeaponHitType.Bodyshot},
        [BoneEnum.UpperLeftLeg] = {modifier = 0.75, type = WeaponHitType.Bodyshot},
        [BoneEnum.UpperRightLeg] = {modifier = 0.75, type = WeaponHitType.Bodyshot},
        [BoneEnum.RightLeg] = {modifier = 0.60, type = WeaponHitType.Bodyshot},
        [BoneEnum.LeftLeg] = {modifier = 0.60, type = WeaponHitType.Bodyshot},
        [BoneEnum.RightFoot] = {modifier = 0.45, type = WeaponHitType.Bodyshot},
        [BoneEnum.LeftFoot] = {modifier = 0.45, type = WeaponHitType.Bodyshot},
        [BoneEnum.RightHand] = {modifier = 0.45, type = WeaponHitType.Bodyshot},
        [BoneEnum.LeftHand] ={modifier =  0.4, type = WeaponHitType.Bodyshot}
    }

    self.FOVDamageModifier = 0.20 -- If hiding behind a wall, how much damage do you absorb 

    self.FireEffectTime = 9 -- Time it takes for fire to go out 
    
    self.FireDamagePerSecond = 0.09
    self.ToxicDamagePerSecond = 0.08
    self.WarpGrenadeDamage = 0.25
    
    self.VehicleGuardDamage = 1.0 -- Instakill
    
    self.SuicideDamage = 999
    
    self.ExplosiveBaseDamage = 
    {
        [DamageEntity.Mine] = {damage = 250, radius = 6, knockback = 10},
        [DamageEntity.Claymore] = {damage = 500, radius = 10, knockback = 12},
        [DamageEntity.C4] = {damage = 400, radius = 50, knockback = 30},
        [DamageEntity.HEGrenade] = {damage = 140, radius = 5, knockback = 5},
        [DamageEntity.LaserGrenade] = {damage = 500, radius = 8, knockback = 60}
    }
    
    self.WeaponHitType = 
    {
        Headshot = 1,
        Bodyshot = 2,
        Explosive = 3,
        Melee = 4
    }
    
    self.MeleeDamage = 
    {
        [DamageEntity.MeleeGrapple] = {damage = 25, knockback = 0},
        [DamageEntity.MeleeKick] = {damage = 15, knockback = 0},
        [DamageEntity.MeleeSlidingKick] = {damage = 30, knockback = 5},
    }

    self.ArmorModifiers = -- Percentages subtracted, 0.2 = 20% less damage = 80% total damage
    {
        ["Helmet"] = 
        {
            [WeaponHitType.Headshot] = 0.2,
            [WeaponHitType.Bodyshot] = 0,
            [WeaponHitType.Explosive] = 0.05,
            [WeaponHitType.Melee] = 0.1,
        },
        ["Police Helmet"] = 
        {
            [WeaponHitType.Headshot] = 0.4,
            [WeaponHitType.Bodyshot] = 0,
            [WeaponHitType.Explosive] = 0.1,
            [WeaponHitType.Melee] = 0.15,
        },
        ["Military Helmet"] = 
        {
            [WeaponHitType.Headshot] = 0.6,
            [WeaponHitType.Bodyshot] = 0,
            [WeaponHitType.Explosive] = 0.15,
            [WeaponHitType.Melee] = 0.2,
        },
        ["Military Vest"] = 
        {
            [WeaponHitType.Headshot] = 0,
            [WeaponHitType.Bodyshot] = 0.3,
            [WeaponHitType.Explosive] = 0.3,
            [WeaponHitType.Melee] = 0.4,
        },
        ["Kevlar Vest"] = 
        {
            [WeaponHitType.Headshot] = 0,
            [WeaponHitType.Bodyshot] = 0.6,
            [WeaponHitType.Explosive] = 0.5,
            [WeaponHitType.Melee] = 0.6,
        },
    }
    

end

function WeaponDamage:GetDamageForWeapon(weapon_enum)
    return self.weapon_damages[weapon_enum]
end

function WeaponDamage:CalculatePlayerDamage(victim, weapon_enum, bone_enum, hit_type, distance)

    local base_damage = self.weapon_damages[weapon_enum].base
    local bone_damage_modifier = self.bone_damage_modifiers[bone_enum]
    local hit_type = self.bone_damage_modifiers[bone_enum].type
    local falloff_modifier = self.weapon_damages[weapon_enum].falloff(distance, self.weapon_damages[weapon_enum].distance_falloff)

    local damage = weapon_damage * bone_damage_modifier * falloff_modifier * 100

    local armor_mod = self:GetArmorMod(victim, hit_type, damage)

    return math.floor(damage) / 100
end

function WeaponDamage:GetArmorMod(player, hit_type, damage)

    assert(IsValid(player), "player was invalid")

    local original_damage = damage

    local equipped_items = player:GetValue("EquippedItems")
    local steam_id = tostring(player:GetSteamId())

    for armor_name, mods in pairs(self.ArmorModifiers) do
        if equipped_items[armor_name] and self.ArmorModifiers[armor_name][hit_type] > 0 then

            damage = damage * (1 - self.ArmorModifiers[armor_name][hit_type])

            -- If the armor prevented some damage, then modify its durability
            if self.ArmorModifiers[armor_name][hit_type] > 0 then
                
                if not self.pending_armor_aggregation[steam_id] then
                    self.pending_armor_aggregation[steam_id] = {}
                end

                if not self.pending_armor_aggregation[steam_id][armor_name] then
                    self.pending_armor_aggregation[steam_id][armor_name] = 
                    {
                        player = player,
                        armor_name = armor_name,
                        damage_diff = original_damage - original_damage * (1 - self.ArmorModifiers[armor_name][hit_type])
                    }
                else
                    self.pending_armor_aggregation[steam_id][armor_name].damage_diff = 
                        self.pending_armor_aggregation[steam_id][armor_name].damage_diff +
                        original_damage - original_damage * (1 - self.ArmorModifiers[armor_name][hit_type])
                end
            end

        end
    end

    return damage

end

WeaponDamage = WeaponDamage()