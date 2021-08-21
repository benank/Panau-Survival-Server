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
        cost_modifier = 0.5 -- Global cost modifier for all vehicles (integer)
    },
    cost_multiplier_on_purchase = 2, -- Cost multiplier after purchasing an unowned vehicle
    max_vehicle_guards = 5, -- Maximum vehicle guards per vehicle
    player_max_vehicles_base = 10,
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
    gas_station_radius = 20,
    gas_station_repair_per_second = 0.015, -- 1.5% per second
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
        [69] = {["Armed"] = 0.1}, -- winstons amen party boat
        [88] = {["Armed"] = 1}, -- only default mta powerruns without weapons spawn in the wild (use FullyUpgraded for MG and rockets, Armed for MG)
        [5] = {["Cab"] = 0.3, ["Fishing"] = 0.3},
        [11] = {["Civil"] = 0.5},
        --[35] = {["Armed"] = 0.01}, -- Garret Traver Z with MG
        [78] = {["Cab"] = 0.5},
        [91] = {["Hardtop"] = 0.3, ["Softtop"] = 0.3},
        [66] = {["Double"] = 0.2},
        [40] = {["Crane"] = 0.1},
        [56] = {["Cab"] = 1}, -- default spawn (use WeaponUpgrade0 for cannon)
        [84] = {["Cab"] = 0.5},
        [31] = {["Cab"] = 0.5}, -- use MG for machine gun
        [77] = {["Default"] = 1}, -- default spawn (use MG for machine gun)
        --[18] = {["Cannon"] = 0.1}, 
        [87] = {["Cab"] = 0.25, ["Softtop"] = 0.25},
        [46] = {["Cab"] = 0.4},
        --[37] = {["WeaponUpgrade1"] = 0.01}, -- Adds rockets
        --[48] = {["BuggyMG"] = 0.05}, -- Maddox Machine Gun
        [3] = {--[[["Armed"] = 0.01,]] ["FullyUpgraded"] = 0.2}, -- Armed Rowlinson K22
        --[62] = {["Dome"] = 0.01, ["default"] = 0.03}, -- Adds rockets or MG, Use UnArmed for unarmed vehicle
        [7] = {["Default"] = 1, --[[["Armed"] = 0.1]]}, -- default (use Armed for MG)
        [81] = {["FullyUpgraded"] = 0.2}
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