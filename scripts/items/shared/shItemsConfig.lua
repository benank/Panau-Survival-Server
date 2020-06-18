ItemsConfig = 
{
    usables = -- No food items here because those have no delay when using them
    {
        ["Mine"] = {use_time = 3, trigger_radius = 1.75, cell_size = 256, trigger_time = 1.5},
        ["Claymore"] = {trigger_range = 3, cell_size = 256, use_time = 5, delay_use = true},
        ["C4"] = {use_time = 6, delay_use = true},
        ["Proximity Alarm"] = {use_time = 4, delay_use = true, range = 10, battery_dura_per_hour = 100}, -- 10% per hour
        ["Bandages"] = {restore_hp = 0.2, use_time = 3},
        ["Healthpack"] = {restore_hp = 1.0, use_time = 10},
        ["Woet"] = {use_time = 1, range = 5},
        ["Vehicle Repair"] = {use_time = 5, range = 5},
        ["Vehicle Guard"] = {use_time = 3, range = 5},
        ["BackTrack"] = {use_time = 3},
        ["EVAC"] = {use_time = 5},
        ["Respawner"] = {use_time = 3}, -- Temp
        ["Car Paint"] = {use_time = 3, range = 5},
        ["Hacker"] = {use_time = 3},
        ["Master Hacker"] = {use_time = 5},
        ["Ping"] = {max_distance = 5000, max_height = 4000},
        ["Combat Ping"] = {max_distance = 550, max_height = 200},
    },
    airstrikes = 
    {
        ["Cruise Missile"] = {delay = 7, radius = 80, damage_entity = DamageEntity.CruiseMissile, plane_velo = 110, plane_id = 34},
        ["Area Bombing"] = {delay = 10, radius = 120, damage_entity = DamageEntity.AreaBombing, plane_velo = 40, plane_id = 85, num_bombs = 30},
        ["Tactical Nuke"] = {delay = 15, radius = 150, damage_entity = DamageEntity.TacticalNuke, plane_velo = 40, plane_id = 34},
    },
    equippables = -- Use equip
    {
        ["Grapplehook"] = {dura_per_sec = 1},
        ["RocketGrapple"] = {dura_per_sec = 4},
        ["Parachute"] = {dura_per_sec = 1.25},
        ["Explosives Detector"] = {dura_per_sec = 5, dura_per_activation = 15, battery_dura_per_sec = 25},
        ["Cloud Strider Boots"] = {dura_per_5_sec = 1},
        ["Stick Disguise"] = {dura_per_hit = 2},
        ["Nitro"] = {dura_per_sec = 20},
        weapons = 
        {
            ["Handgun"] = {dura_per_use = 1, weapon_id = Weapon.Handgun, equip_slot = WeaponSlot.Right},
            ["Assault Rifle"] = {dura_per_use = 1, weapon_id = Weapon.Assault, equip_slot = WeaponSlot.Primary},
            ["Bubble Gun"] = {dura_per_use = 1, weapon_id = Weapon.BubbleGun, equip_slot = WeaponSlot.Right},
            ["Grenade Launcher"] = {dura_per_use = 5, weapon_id = Weapon.GrenadeLauncher, equip_slot = WeaponSlot.Right},
            ["Machine Gun"] = {dura_per_use = 2, weapon_id = Weapon.MachineGun, equip_slot = WeaponSlot.Primary},
            ["Revolver"] = {dura_per_use = 1, weapon_id = Weapon.Revolver, equip_slot = WeaponSlot.Right},
            ["Rocket Launcher"] = {dura_per_use = 10, weapon_id = Weapon.RocketLauncher, equip_slot = WeaponSlot.Primary},
            ["SMG"] = {dura_per_use = 1, weapon_id = Weapon.SMG, equip_slot = WeaponSlot.Right},
            ["Sawn-Off Shotgun"] = {dura_per_use = 2, weapon_id = Weapon.SawnOffShotgun, equip_slot = WeaponSlot.Right},
            ["Shotgun"] = {dura_per_use = 3, weapon_id = Weapon.Shotgun, equip_slot = WeaponSlot.Primary},
            ["Sniper Rifle"] = {dura_per_use = 5, weapon_id = Weapon.Sniper, equip_slot = WeaponSlot.Primary},
        },
        armor = 
        {
            ["Helmet"] = {dura_per_hit = 10},
            ["Police Helmet"] = {dura_per_hit = 6},
            ["Military Helmet"] = {dura_per_hit = 4},
            ["Military Vest"] = {dura_per_hit = 6},
            ["Kevlar Vest"] = {dura_per_hit = 2}
        },
        backpacks = 
        {
            ["Combat Backpack"] = {     dura_per_hit = 2,   slots = {Weapons = 2, Explosives = 2, Supplies = 0, Survival = 1}},
            ["Explorer Backpack"] = {   dura_per_hit = 2,   slots = {Weapons = 0, Explosives = 0, Supplies = 2, Survival = 3}},
            ["Military Vest"] = {       dura_per_hit = 2,   slots = {Weapons = 1, Explosives = 1, Supplies = 0, Survival = 0}}
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
    },
    use_time_perks = 
    {
        ["Bandages"] = 
        {
            [19] = 0.75,
            [36] = 0.5
        },
        ["Healthpack"] = 
        {
            [60] = 0.75,
            [85] = 0.5
        },
    }
}

BackpackPerks = 
{
    [10] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    },
    [37] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    },
    [64] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    },
    [79] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    },
    [100] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    },
    [120] = 
    {
        [1] = {Weapons = 0, Explosives = 1, Supplies = 1, Survival = 0},
        [2] = {Weapons = 0, Explosives = 0, Supplies = 1, Survival = 1},
    }
}


-- Num bombs perks for Area Bombing (bonuses)
AirstrikePerks = 
{
    ["Area Bombing"] = 
    {
        [108] = {[2] = 5},
        [173] = {[2] = 10}
    },
    ["Cruise Missile"] = 
    {
        [74] =  {[2] = 1.10},
        [131] = {[2] = 1.20}
    },
    ["Tactical Nuke"] = 
    {
        [140] = {[2] = 1.10},
        [198] = {[2] = 1.20}
    },
}


DisabledPlacementModels = 
{
    ["geo.cbb.eez/go152-a.lod"] = true,
    ["38x11.nl/go231-a.lod"] = true,
    ["f1t16.garbage_can.eez/go225-a.lod"] = true,
    ["areaset03.blz/go161-a1_dst.lod"] = true
}