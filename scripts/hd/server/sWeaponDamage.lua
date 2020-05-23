class "WeaponDamage"

function WeaponDamage:__init()
    self.weapon_damages = {
        [WeaponEnum.MachineGun] = 0.10
    }

    self.bone_damage_modifiers = {
        [BoneEnum.Head] = 3.0,
        [BoneEnum.Neck] = 1.5,
        [BoneEnum.Spine1] = 1.0,
        [BoneEnum.Spine2] = 1.0,
        [BoneEnum.Hips] = 0.8,
        [BoneEnum.LeftForeArm] = 0.65,
        [BoneEnum.RightForeArm] = 0.65,
        [BoneEnum.LeftArm] = 0.75,
        [BoneEnum.RightArm] = 0.75,
        [BoneEnum.UpperLeftLeg] = 0.75,
        [BoneEnum.UpperRightLeg] = 0.75,
        [BoneEnum.RightLeg] = 0.60,
        [BoneEnum.LeftLeg] = 0.60,
        [BoneEnum.RightFoot] = 0.45,
        [BoneEnum.LeftFoot] = 0.45,
        [BoneEnum.RightHand] = 0.45,
        [BoneEnum.LeftHand] = 0.45
    }
end

function WeaponDamage:GetDamageForWeapon(weapon_enum)
    return self.weapon_damages[weapon_enum]
end

function WeaponDamage:CalculatePlayerDamage(weapon_enum, bone_enum)
    local weapon_damage = self.weapon_damages[weapon_enum]
    local bone_damage_modifier = self.bone_damage_modifiers[bone_enum]
    
    return math.floor(weapon_damage * bone_damage_modifier * 100) / 100
end

WeaponDamage = WeaponDamage()
