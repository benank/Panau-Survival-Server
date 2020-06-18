config = 
{
    spawn = 
    {
        ["MIL_HEL"] = {cost = 100, spawn_chance = 0.5, respawn_interval = 120}, -- base cost + chance of spawning at beginning + per hour/respawn
        ["MIL_PLA_L"] = {cost = 100, spawn_chance = 0.5, respawn_interval = 120},
        ["MIL_PLA_M"] = {cost = 75, spawn_chance = 0.63, respawn_interval = 90},
        ["URB_HEL"] = {cost = 60, spawn_chance = 0.7, respawn_interval = 72},
        ["URB_PLA_M"] = {cost = 50, spawn_chance = 0.75, respawn_interval = 60},
        ["MIL_SEA_L"] = {cost = 50, spawn_chance = 0.75, respawn_interval = 60},
        ["URB_PLA_S"] = {cost = 50, spawn_chance = 0.75, respawn_interval = 60},
        ["MIL_SEA_M"] = {cost = 40, spawn_chance = 0.8, respawn_interval = 48},
        ["MIL_CAR_L"] = {cost = 40, spawn_chance = 0.8, respawn_interval = 48},
        ["URB_PLA_L"] = {cost = 40, spawn_chance = 0.8, respawn_interval = 48},
        ["MIL_CAR_M"] = {cost = 30, spawn_chance = 0.85, respawn_interval = 36},
        ["URB_SEA"] = {cost = 30, spawn_chance = 0.85, respawn_interval = 36},
        ["URB_CAR_M"] = {cost = 25, spawn_chance = 0.88, respawn_interval = 30},
        ["RUR_PLA"] = {cost = 25, spawn_chance = 0.88, respawn_interval = 30},
        ["MIL_BIK"] = {cost = 15, spawn_chance = 0.93, respawn_interval = 18},
        ["URB_CAR_L"] = {cost = 15, spawn_chance = 0.93, respawn_interval = 18},
        ["URB_CAR_S"] = {cost = 13, spawn_chance = 0.94, respawn_interval = 16},
        ["URB_BIK"] = {cost = 13, spawn_chance = 0.94, respawn_interval = 16},
        ["RUR_CAR_M"] = {cost = 10, spawn_chance = 0.95, respawn_interval = 12},
        ["RUR_CAR_L"] = {cost = 8, spawn_chance = 0.96, respawn_interval = 10},
        ["RUR_SEA_L"] = {cost = 5, spawn_chance = 0.98, respawn_interval = 6},
        ["RUR_SEA_M"] = {cost = 5, spawn_chance = 0.98, respawn_interval = 6},
        ["RUR_CAR_S"] = {cost = 5, spawn_chance = 0.98, respawn_interval = 6},
        ["RUR_BIK"] = {cost = 5, spawn_chance = 0.98, respawn_interval = 6},
        cost_overrides = -- Vehicle-specific price overrides (such as topa)
        {
            [64] = 200,
            [66] = 30,
            [79] = 30,
            [58] = 50,
            [1] = 10,
            [82] = 30,
            [4] = 20,
            [12] = 20,
            [20] = 80,
            [88] = 100,
            [77] = 70,
            [7] = 50,
            [75] = 50,
            [24] = 200,
            [53] = 100,
        },
        half_off_chance = 0.002,
        health = {max = 1, min = 0.7},
        cost_modifier = 1 -- Global cost modifier for all vehicles (integer)
    },
    cost_multiplier_on_purchase = 3, -- Cost multiplier after purchasing an unowned vehicle
    max_vehicle_guards = 5, -- Maximum vehicle guards per vehicle
    player_max_vehicles_base = 3,
    player_max_vehicles =  -- Vehicle bonuses per perk
    {
        [7] = 1,
        [25] = 1,
        [47] = 1,
        [66] = 1,
        [77] = 1,
        [92] = 1,
        [112] = 1,
        [126] = 1,
        [136] = 1,
        [143] = 1,
        [154] = 1,
        [165] = 1,
        [170] = 1,
        [176] = 1,
        [183] = 1,
        [189] = 1,
        [195] = 1,
        [201] = 1,
        [206] = 1,
        [210] = 1,
        [215] = 1,
        [218] = 1,
        [222] = 1,
        [227] = 1,
        [231] = 1
    },
    owned_despawn_time = 5, -- Minutes it takes for vehicles to despawn after owner leaves
    gas_station_radius = 15,
    decals = -- List of all possible vehicle decals
    {
        "MilStandard",
        "OldJapan",
        "Reapers",
        "Roaches",
        "UlarBoys",
        "Taxi",
        "Licenseplate"
    },
    decal_chance = 0.2,
    templates = -- Use these templates for spawning
    {
        [69] = {chance = 0.1, templates = {"Armed"}}, -- winstons amen party boat
        [88] = {chance = 1, templates = {"Default"}}, -- only default mta powerruns without weapons spawn in the wild (use FullyUpgraded for MG and rockets, Armed for MG)
        [5] = {chance = 0.6, templates = {"Cab", "Fishing"}},
        [11] = {chance = 0.5, templates = {"Civil"}},
        [35] = {chance = 0.01, templates = {"Armed"}}, -- Garret Traver Z with MG
        [78] = {chance = 0.5, templates = {"Cab"}},
        [91] = {chance = 0.6, templates = {"Hardtop", "Softtop"}},
        [66] = {chance = 0.2, templates = {"Double"}},
        [40] = {chance = 0.1, templates = {"Crane"}},
        [56] = {chance = 1, templates = {"Cab"}}, -- default spawn (use WeaponUpgrade0 for cannon)
        [84] = {chance = 0.5, templates = {"Cab"}},
        [31] = {chance = 0.5, templates = {"Cab"}}, -- use MG for machine gun
        [77] = {chance = 1, templates = {"Default"}}, -- default spawn (use MG for machine gun)
        [18] = {chance = 0.1, templates = {"Cannon"}}, 
        [87] = {chance = 0.5, templates = {"Cab", "Softtop"}},
        [46] = {chance = 0.4, templates = {"Cab"}},
        [37] = {chance = 0.01, templates = {"WeaponUpgrade1"}}, -- Adds rockets
        [48] = {chance = 0.01, templates = {"BuggyMG"}}, -- Maddox Machine Gun
        [3] = {chance = 0.01, templates = {"Armed"}}, -- Armed Rowlinson K22
        [62] = {chance = 0.01, templates = {"Dome", "default"}}, -- Adds rockets or MG, Use UnArmed for unarmed vehicle
        [7] = {chance = 1, templates = {"Default"}} -- default (use Armed for MG)
    },
    colors = -- HSV car colors based on the biome they spawn in
    {
        [ClimateZone.Arctic] = 
        {
            h_min = 0,
            h_max = 360,
            s_min = 0,
            s_max = 18,
            v_min = 62,
            v_max = 100
        },
        [ClimateZone.City] = 
        {
            h_min = 0,
            h_max = 360,
            s_min = 0,
            s_max = 75,
            v_min = 25,
            v_max = 75
        },
        [ClimateZone.Desert] = 
        {
            h_min = 13,
            h_max = 62,
            s_min = 15,
            s_max = 65,
            v_min = 75,
            v_max = 100
        },
        [ClimateZone.Grass] = 
        {
            h_min = 82,
            h_max = 159,
            s_min = 5,
            s_max = 50,
            v_min = 15,
            v_max = 80
        },
        [ClimateZone.Jungle] = 
        {
            h_min = 82,
            h_max = 159,
            s_min = 10,
            s_max = 90,
            v_min = 10,
            v_max = 90
        },
        [ClimateZone.Sea] = 
        {
            h_min = 0,
            h_max = 360,
            s_min = 0,
            s_max = 75,
            v_min = 25,
            v_max = 75
        },
        default = 
        {
            h_min = 0,
            h_max = 360,
            s_min = 5,
            s_max = 60,
            v_min = 5,
            v_max = 60
        }
    }
}