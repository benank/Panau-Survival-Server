ItemsConfig = 
{
    usables = -- No food items here because those have no delay when using them
    {
        ["Mine"] = {use_time = 3},
        ["Bandages"] = {restore_hp = 0.2, use_time = 3},
        ["Healthpack"] = {restore_hp = 0.5, use_time = 5},
        ["Woet"] = {use_time = 2},

    },
    equippables = -- Use equip
    {
        ["Grapplehook"] = {dura_per_sec = 1},
        ["RocketGrapple"] = {dura_per_sec = 2},
        ["Parachute"] = {dura_per_sec = 1},
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
            ["Helmet"] = {dura_per_hit = 1},
            ["Police Helmet"] = {dura_per_hit = 1},
            ["Military Helmet"] = {dura_per_hit = 1},
            ["Military Vest"] = {dura_per_hit = 1},
            ["Elite Vest"] = {dura_per_hit = 1}
        },
        backpacks = 
        {
            ["Combat Backpack"] = {dura_per_hit = 1,    slots = {Weapons = 2, Explosives = 4, Supplies = 4, Survival = 0}},
            ["Explorer Backpack"] = {dura_per_hit = 1,  slots = {Weapons = 1, Explosives = 1, Supplies = 4, Survival = 4}},
            ["Military Vest"] = {dura_per_hit = 1,      slots = {Weapons = 1, Explosives = 1, Supplies = 0, Survival = 0}}
        }
    }
}