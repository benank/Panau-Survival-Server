WeaponBaseDamage = 
{
    [Weapon.Handgun] = 4, -- All of these are in percents
    [Weapon.Assault] = 5,
    [Weapon.BubbleGun] = -2,
    [Weapon.GrenadeLauncher] = 50,
    [Weapon.MachineGun] = 8,
    [Weapon.Revolver] = 12,
    [Weapon.RocketLauncher] = 110,
    [Weapon.SMG] = 5,
    [Weapon.Sniper] = 80,
    [Weapon.SawnOffShotgun] = 3, -- Damage per bullet in each shot
    [Weapon.Shotgun] = 5,
}

FireDamagePerSecond = 0.05

ExplosiveBaseDamage = 
{
    ["Mine"] = {damage = 130, radius = 10, knockback = 10},
    ["Claymore"] = {damage = 150, radius = 10, knockback = 12},
    ["HE Grenade"] = {damage = 110, radius = 5, knockback = 5},
    ["Laser Grenade"] = {damage = 300, radius = 8, knockback = 60}
}

WeaponHitType = 
{
    Headshot = 1,
    Bodyshot = 2,
    Explosive = 3,
    Melee = 4
}

BoneModifiers =  -- Percentages of total damage, 1.0 = no change, 0.5 = half damage
{
    ["ragdoll_AttachHandLeft"] = {  mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_AttachHandRight"] = { mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_Head"] = {            mod = 2.00, type = WeaponHitType.Headshot},
    ["ragdoll_Hips"] = {            mod = 0.85, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftArm"] ={          mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftFoot"] = {        mod = 0.25, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftForeArm"] ={      mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftHand"] = {        mod = 0.25, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftLeg"] = {         mod = 0.75, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftShoulder"] = {    mod = 0.85, type = WeaponHitType.Bodyshot},
    ["ragdoll_LeftUpLeg"] = {       mod = 0.75, type = WeaponHitType.Bodyshot},
    ["ragdoll_Neck"] = {            mod = 1.75, type = WeaponHitType.Headshot},
    ["ragdoll_Reference"] = {       mod = 1.00, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightArm"] = {        mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightFoot"] = {       mod = 0.25, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightForeArm"] = {    mod = 0.50, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightHand"] = {       mod = 0.25, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightLeg"] = {        mod = 0.75, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightShoulder"] = {   mod = 0.85, type = WeaponHitType.Bodyshot},
    ["ragdoll_RightUpLeg"] = {      mod = 0.75, type = WeaponHitType.Bodyshot},
    ["ragdoll_Spine"] = {           mod = 1.00, type = WeaponHitType.Bodyshot},
    ["ragdoll_Spine1"] = {          mod = 1.00, type = WeaponHitType.Bodyshot}
}

ArmorModifiers = -- Percentages subtracted, 0.2 = 20% less damage = 80% total damage
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