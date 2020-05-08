ItemsConfig = 
{
    usables = -- No food items here because those have no delay when using them
    {
        ["Mine"] = {use_time = 3, trigger_radius = 1.5, cell_size = 256, trigger_time = 1.5},
        ["Claymore"] = {trigger_range = 3, cell_size = 256},
        ["Bandages"] = {restore_hp = 0.2, use_time = 3},
        ["Healthpack"] = {restore_hp = 0.5, use_time = 5},
        ["Woet"] = {use_time = 1, range = 5},
        ["Vehicle Repair"] = {use_time = 5, range = 5},
        ["Vehicle Guard"] = {use_time = 3, range = 5},
        ["BackTrack"] = {use_time = 3},
        ["EVAC"] = {use_time = 5},
    },
    equippables = -- Use equip
    {
        ["Grapplehook"] = {dura_per_sec = 1},
        ["RocketGrapple"] = {dura_per_sec = 3},
        ["Parachute"] = {dura_per_sec = 1},
        ["Explosives Detector"] = {dura_per_sec = 1, dura_per_activation = 30, battery_dura_per_sec = 5},
        weapons = 
        {
            ["Handgun"] = {dura_per_use = 1, weapon_id = Weapon.Handgun, equip_slot = WeaponSlot.Right},
            ["Assault Rifle"] = {dura_per_use = 3, weapon_id = Weapon.Assault, equip_slot = WeaponSlot.Primary},
            ["Bubble Gun"] = {dura_per_use = 1, weapon_id = Weapon.BubbleGun, equip_slot = WeaponSlot.Right},
            ["Grenade Launcher"] = {dura_per_use = 5, weapon_id = Weapon.GrenadeLauncher, equip_slot = WeaponSlot.Right},
            ["Machine Gun"] = {dura_per_use = 4, weapon_id = Weapon.MachineGun, equip_slot = WeaponSlot.Primary},
            ["Revolver"] = {dura_per_use = 1, weapon_id = Weapon.Revolver, equip_slot = WeaponSlot.Right},
            ["Rocket Launcher"] = {dura_per_use = 20, weapon_id = Weapon.RocketLauncher, equip_slot = WeaponSlot.Primary},
            ["SMG"] = {dura_per_use = 1, weapon_id = Weapon.SMG, equip_slot = WeaponSlot.Right},
            ["Sawn-Off Shotgun"] = {dura_per_use = 3, weapon_id = Weapon.SawnOffShotgun, equip_slot = WeaponSlot.Right},
            ["Shotgun"] = {dura_per_use = 5, weapon_id = Weapon.Shotgun, equip_slot = WeaponSlot.Primary},
            ["Sniper Rifle"] = {dura_per_use = 10, weapon_id = Weapon.Sniper, equip_slot = WeaponSlot.Primary},
        },
        armor = 
        {
            ["Helmet"] = {dura_per_hit = 10},
            ["Police Helmet"] = {dura_per_hit = 6},
            ["Military Helmet"] = {dura_per_hit = 4},
            ["Military Vest"] = {dura_per_hit = 6},
            ["Kevlar Vest"] = {dura_per_hit = 4}
        },
        backpacks = 
        {
            ["Combat Backpack"] = {dura_per_hit = 2,    slots = {Weapons = 2, Explosives = 4, Supplies = 4, Survival = 0}},
            ["Explorer Backpack"] = {dura_per_hit = 2,  slots = {Weapons = 1, Explosives = 1, Supplies = 4, Survival = 4}},
            ["Military Vest"] = {dura_per_hit = 2,      slots = {Weapons = 1, Explosives = 1, Supplies = 0, Survival = 0}}
        },
        grenades = 
        {
            ["HE Grenade"] = DamageEntity.HEGrenade,
            ["Molotov"] = DamageEntity.Molotov,
            ["Smoke Grenade"] = DamageEntity.None,
            ["Toxic Grenade"] = DamageEntity.ToxicGrenade,
            ["Flashbang"] = DamageEntity.None,
            ["Flares"] = DamageEntity.None,
            ["AntiGrav Grenade"] = DamageEntity.None,
            ["Warp Grenade"] = DamageEntity.None,
            ["Laser Grenade"] = DamageEntity.LaserGrenade,
        }
    }
}