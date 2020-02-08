ItemsConfig = 
{
    usables = -- No food items here because those have no delay when using them
    {
        ["Mine"] = {use_time = 3},
        ["Medkit"] = {restore_hp = 0.5, use_time = 3},
        ["Medpack"] = {restore_hp = 1, use_time = 5},
        ["Woet"] = {use_time = 2},

    },
    equippables = -- Use equip
    {
        ["Parachute"] = {dura_per_sec = 1},
        ["Grapplehook Upgrade - Recharge"] = {dura_per_use = -1},
        ["Grapplehook Upgrade - Speed"] = {dura_per_sec = -1},
        ["Grapplehook Upgrade - Range"] = {dura_per_sec = -1},
        ["Grapplehook Upgrade - Underwater"] = {dura_per_sec = -1},
        ["Grapplehook Upgrade - Gun"] = {dura_per_sec = -1},
        ["Grapplehook Upgrade - Impulse"] = {dura_per_sec = -1},
        ["Grapplehook Upgrade - Smart"] = {dura_per_use = -1},
        weapons = 
        {
            ["Pistol"] = {dura_per_use = -1, weapon_id = Weapon.Handgun, equip_slot = WeaponSlot.Right},
            ["Assault"] = {dura_per_use = -1, weapon_id = Weapon.Assault, equip_slot = WeaponSlot.Primary},
            ["Bubble Gun"] = {dura_per_use = -1, weapon_id = Weapon.BubbleGun, equip_slot = WeaponSlot.Right},
            ["Grenade Launcher"] = {dura_per_use = -1, weapon_id = Weapon.GrenadeLauncher, equip_slot = WeaponSlot.Right},
            ["Machine Gun"] = {dura_per_use = -1, weapon_id = Weapon.MachineGun, equip_slot = WeaponSlot.Primary},
            ["Revolver"] = {dura_per_use = -1, weapon_id = Weapon.Revolver, equip_slot = WeaponSlot.Right},
            ["Rocket Launcher"] = {dura_per_use = -1, weapon_id = Weapon.RocketLauncher, equip_slot = WeaponSlot.Primary},
            ["Submachine Gun"] = {dura_per_use = -1, weapon_id = Weapon.SMG, equip_slot = WeaponSlot.Right},
            ["Sawn-Off Shotgun"] = {dura_per_use = -1, weapon_id = Weapon.SawnOffShotgun, equip_slot = WeaponSlot.Right},
            ["Shotgun"] = {dura_per_use = -1, weapon_id = Weapon.Shotgun, equip_slot = WeaponSlot.Primary},
            ["Sniper Rifle"] = {dura_per_use = -1, weapon_id = Weapon.Sniper, equip_slot = WeaponSlot.Primary},
        },
        ["Grid Armor MKI"] = {dura_per_hit = -1},
        ["Military Vest"] = {dura_per_hit = -1},
        ["Repair Hammer"] = {dura_per_use = -10}
    }
}