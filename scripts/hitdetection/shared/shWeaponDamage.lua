class "WeaponDamage"

function WeaponDamage:__init()

    if Server then
        self.pending_armor_aggregation = {}
    end

    -- Start losing damage at distance_falloff / 2, and 0 damage past distance_falloff
    local falloff_func = function(distance, distance_falloff)
        return math.clamp(1 - (distance - distance_falloff / 2) / (distance_falloff / 2), 0, 1)
    end

    self.weapon_damages = {
        [WeaponEnum.MachineGun] =       {base = 0.10, v_mod = 0.08,  distance_falloff = 500, falloff = falloff_func},
        [WeaponEnum.Handgun] =          {base = 0.09, v_mod = 0.05,  distance_falloff = 150, falloff = falloff_func},
        [WeaponEnum.Assault] =          {base = 0.09, v_mod = 0.08,  distance_falloff = 300, falloff = falloff_func},
        [WeaponEnum.BubbleGun] =        {base =-0.02, v_mod = 0,     distance_falloff = 50,  falloff = falloff_func},
        [WeaponEnum.GrenadeLauncher] =  {base = 0.12, v_mod = 3,     distance_falloff = 0,   falloff = function() return 1 end, radius = 5},
        [WeaponEnum.Revolver] =         {base = 0.18, v_mod = 0.05,  distance_falloff = 300, falloff = falloff_func},
        [WeaponEnum.RocketLauncher] =   {base = 0.15, v_mod = 4,     distance_falloff = 0,   falloff = function() return 1 end, radius = 4},
        [WeaponEnum.SMG] =              {base = 0.08, v_mod = 0.02,  distance_falloff = 100, falloff = falloff_func},
        [WeaponEnum.Sniper] =           {base = 0.90, v_mod = 0.04,  distance_falloff = 150, falloff = 
            function(distance, distance_falloff) -- Sniper gains full power at 200+ meters away
                return math.clamp(distance / distance_falloff, 0, 1)
            end},
        [WeaponEnum.SawnOffShotgun] =   {base = 0.15, v_mod = 0.05,   distance_falloff = 80,  falloff = falloff_func},
        [WeaponEnum.Shotgun] =          {base = 0.18, v_mod = 0.05,   distance_falloff = 100, falloff = falloff_func},
        
        -- Vehicle Weapons
        [WeaponEnum.V_Minigun] =        {base = 0.08, v_mod = 1,     distance_falloff = 500, falloff = falloff_func},
        [WeaponEnum.V_Rockets] =        {base = 0.30, v_mod = 2,     distance_falloff = 0,   falloff = function() return 1 end, radius = 12},
        [WeaponEnum.V_Cannon] =         {base = 0.15, v_mod = 2,     distance_falloff = 0,   falloff = function() return 1 end, radius = 6},
        [WeaponEnum.V_MachineGun] =     {base = 0.10, v_mod = 0.5,   distance_falloff = 300, falloff = falloff_func}
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

    self.default_vehicle_armor = 1 -- 1x damage multiplier, lower = less damage

    self.vehicle_armors = -- Vehicle armors, indexed by vehicle model id. If not here, then it uses default armor
    {
        [30] = 0.25, -- Si-47 Leopard
        [34] = 0.1, -- G9 Eclpise
        [37] = 0.5, -- Havoc
        [57] = 0.5, -- Havoc
        [62] = 0.3, -- Chippewa
        [64] = 0.15, -- Topa
        [85] = 0.05, -- Bering
        [69] = 0.5, -- Winstons amen 69
        [50] = 0.1, -- Zhejiang
        [4] = 0.5, -- fire truck
        [18] = 0.1, -- SV-1003 Raider
        [31] = 0.2, -- URGA-9380
        [22] = 0.3, -- Fengding EC14FD2
        [49] = 0.5, -- 	Niseco Tusker D18
        [56] = 0.1, -- 	GV-104 Razorback
        [76] = 0.1 -- 	SAAS PP30 Ox
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
        [DamageEntity.Mine] = {damage = 250, radius = 6, knockback = 10, v_mod = 0.02},
        [DamageEntity.Claymore] = {damage = 500, radius = 10, knockback = 12, v_mod = 0.015},
        [DamageEntity.C4] = {damage = 400, radius = 40, knockback = 20, v_mod = 0.03},
        [DamageEntity.HEGrenade] = {damage = 200, radius = 7, knockback = 5, v_mod = 0.009},
        [DamageEntity.LaserGrenade] = {damage = 500, radius = 8, knockback = 30, v_mod = 0.008}
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
        [DamageEntity.MeleeKick] = {damage = 10, knockback = 0},
        [DamageEntity.MeleeSlidingKick] = {damage = 20, knockback = 5},
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

function WeaponDamage:CalculateVehicleDamage(vehicle, weapon_enum, distance)

    if vehicle:GetValue("InSafezone") then return 0 end
    if vehicle:GetHealth() <= 0 then return 0 end

    local base_damage = self.weapon_damages[weapon_enum].base
    local v_mod = self.weapon_damages[weapon_enum].v_mod
    local falloff_modifier = self.weapon_damages[weapon_enum].falloff(distance, self.weapon_damages[weapon_enum].distance_falloff)
    local vehicle_armor = self.vehicle_armors[vehicle:GetModelId()] or self.default_vehicle_armor

    local damage = base_damage * falloff_modifier * v_mod * vehicle_armor

    return damage

end

function WeaponDamage:CalculatePlayerDamage(victim, weapon_enum, bone_enum, distance)

    if victim:GetValue("InSafezone") then return 0 end
    if victim:GetHealth() <= 0 then return 0 end

    local base_damage = self.weapon_damages[weapon_enum].base
    local bone_damage_modifier = self.bone_damage_modifiers[bone_enum].modifier
    local hit_type = self.bone_damage_modifiers[bone_enum].type
    local falloff_modifier = self.weapon_damages[weapon_enum].falloff(distance, self.weapon_damages[weapon_enum].distance_falloff)
    local armor_mod = self:GetArmorMod(victim, hit_type, base_damage)

    if weapon_enum == WeaponEnum.BubbleGun then
        return base_damage
    end

    local damage = base_damage * bone_damage_modifier * armor_mod * falloff_modifier

    return damage
end

function WeaponDamage:CalculateMeleeDamage(victim, damage_entity)

    if victim:GetValue("InSafezone") then return 0 end
    if victim:GetHealth() <= 0 then return 0 end

    local base_damage = self.MeleeDamage[damage_entity].damage
    local armor_mod = self:GetArmorMod(victim, WeaponHitType.Melee, base_damage)

    local damage = base_damage * armor_mod

    return damage / 100

end

function WeaponDamage:GetArmorMod(player, hit_type, damage)

    assert(IsValid(player), "player was invalid")

    local original_damage = damage
    local mod = 1

    local equipped_items = player:GetValue("EquippedItems")
    local steam_id = tostring(player:GetSteamId())

    for armor_name, mods in pairs(self.ArmorModifiers) do
        if equipped_items[armor_name] and self.ArmorModifiers[armor_name][hit_type] > 0 then

            mod = mod * (1 - self.ArmorModifiers[armor_name][hit_type])

            -- TODO: move this to sHitDetection
            if Server then
                -- If the armor prevented some damage, then modify its durability
                if self.ArmorModifiers[armor_name][hit_type] > 0 then
                    
                    if not sHitDetection.pending_armor_aggregation[steam_id] then
                        sHitDetection.pending_armor_aggregation[steam_id] = {}
                    end

                    if not sHitDetection.pending_armor_aggregation[steam_id][armor_name] then
                        sHitDetection.pending_armor_aggregation[steam_id][armor_name] = 
                        {
                            player = player,
                            armor_name = armor_name,
                            damage_diff = original_damage - original_damage * (1 - self.ArmorModifiers[armor_name][hit_type])
                        }
                    else
                        sHitDetection.pending_armor_aggregation[steam_id][armor_name].damage_diff = 
                            sHitDetection.pending_armor_aggregation[steam_id][armor_name].damage_diff +
                            original_damage - original_damage * (1 - self.ArmorModifiers[armor_name][hit_type])
                    end
                end
            end

        end
    end

    return mod

end

WeaponDamage = WeaponDamage()