config = 
{
    spawn = 
    {
        ["CIV_GROUND"] = {cost = 4, spawn_chance = 0.9}, -- base cost + chance of spawning at beginning + per hour/respawn
        ["CIV_WATER"] = {cost = 7, spawn_chance = 0.8},
        ["CIV_HELI"] = {cost = 15, spawn_chance = 0.7},
        ["CIV_PLANE"] = {cost = 13, spawn_chance = 0.8},
        ["CIV_PLANE_LARGE"] = {cost = 16, spawn_chance = 0.3},
        ["MIL_GROUND"] = {cost = 10, spawn_chance = 0.7},
        ["MIL_WATER"] = {cost = 20, spawn_chance = 0.7},
        ["MIL_HELI"] = {cost = 30, spawn_chance = 0.5},
        ["MIL_PLANE"] = {cost = 40, spawn_chance = 0.5},
        cost_overrides = -- Vehicle-specific price overrides (such as topa)
        {
            [64] = 100, -- Topachula
            [85] = 55, -- Bering
            [75] = 30, -- tuktuk boomboom
            [11] = 2, -- motorcycle
            [21] = 2, -- motorcycle
            [32] = 2, -- motorcycle
            [36] = 2, -- motorcycle
            [43] = 2, -- motorcycle
            [46] = 2, -- motorcycle
            [47] = 2, -- motorcycle
            [61] = 2, -- motorcycle
            [74] = 2, -- motorcycle
            [83] = 2, -- motorcycle
            [89] = 2, -- motorcycle
            [90] = 2, -- motorcycle
            [56] = 40, -- razorback tank
            [18] = 50 -- raider/stonewall tank
        },
        variance = 0.15,
        health = {max = 1, min = 0.6},
        cost_modifier = 1 -- Global cost modifier for all vehicles (integer)
    },
    cost_multiplier_on_purchase = 3, -- Cost multiplier after purchasing an unowned vehicle
    max_vehicle_guards = 5, -- Maximum vehicle guards per vehicle
    player_max_vehicles = 10, -- Maximum 10 vehicles owned at a time TODO: add levels into max vehicles owned
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
    decal_chance = 0.05,
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