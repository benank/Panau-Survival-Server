config = 
{
    spawn = 
    {
        ["CIV_GROUND"] = {cost = 4, spawn_chance = 0.8}, -- base cost + chance of spawning at beginning + per hour/respawn
        ["CIV_WATER"] = {cost = 8, spawn_chance = 0.8},
        ["CIV_HELI"] = {cost = 15, spawn_chance = 0.7},
        ["CIV_PLANE"] = {cost = 15, spawn_chance = 0.8},
        ["CIV_PLANE_LARGE"] = {cost = 16, spawn_chance = 0.3},
        ["MIL_GROUND"] = {cost = 7, spawn_chance = 0.7},
        ["MIL_WATER"] = {cost = 10, spawn_chance = 0.7},
        ["MIL_HELI"] = {cost = 25, spawn_chance = 0.5},
        ["MIL_PLANE"] = {cost = 17, spawn_chance = 0.6},
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
            [90] = 2 -- motorcycle
            -- TODO put price overrides for tanks
        },
        variance = 0.15,
        health = {max = 1, min = 0.8},
        cost_modifier = 7 -- Global cost modifier for all vehicles
    },
    player_max_vehicles = 10, -- Maximum 10 vehicles owned at a time
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
    upgrades = 
    {
        ["RadarMount"] = 
        {
            name = "Radar Mount",
            description = "Mounts a radar to the vehicle for long range scouting.",
            cost = 30,
            id = {},
            type = "passive"
        },
        ["Shield"] = 
        {
            name = "Shield",
            description = "An energy shield protects your vehicle from harm. Recharges over time.",
            cost = 30,
            id = {},
            type = "defensive"
        },
        ["Underwater"] = 
        {
            name = "Underwater",
            description = "Allows the vehicle to traverse underwater.",
            cost = 30,
            id = {},
            type = "passive"
        },
        ["Transformer"] = 
        {
            name = "Transformer",
            description = "The vehicle can switch between a land, sea, and air form seamlessly.",
            cost = 30,
            type = "transformer",
            disabled = true, -- Does not display in menu
            car_d = 35, -- Garret Traver Z
            plane_id = 81, -- Pell Silverbolt
            boat_id = 80 -- Frisco Catshark
        },
        ["Camouflage"] = 
        {
            name = "Camouflage",
            description = "The vehicle will change color to blend in with time of day and biome.",
            cost = 30,
            id = {},
            type = "passive"
        },
        ["RowlinsonK22Armed"] = 
        {
            name = "Machine Guns",
            description = "Adds machine guns to the vehicle.",
            template = "Armed",
            cost = 30,
            id = {3},
            type = "offensive"
        },
        ["BeringBombsight"] = 
        {
            name = "Bering Bombsight",
            description = "Adds a bombsight to the vehicle for an explosive advantage.",
            cost = 70,
            id = {85},
            type = "offensive"
        },
        ["MTAPowerrunRockets"] = 
        {
            name = "Rockets and Machine Gun",
            description = "Adds a machine gun and rockets to the vehicle.",
            template = "FullyUpgraded",
            cost = 60,
            id = {88},
            type = "offensive"
        },
        ["MTAPowerrunMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "Armed",
            cost = 20,
            id = {88},
            type = "offensive"
        },
        ["GarretTraverZMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "Armed",
            cost = 20,
            id = {35},
            type = "offensive"
        },
        ["PolomaRenegadeMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "Armed",
            cost = 20,
            id = {7},
            type = "offensive"
        },
        ["RazorbackCannon"] = 
        {
            name = "Cannon",
            description = "Adds a cannon to the vehicle.",
            template = "WeaponUpgrade0",
            cost = 20,
            id = {56},
            type = "offensive"
        },
        ["URGAMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "MG",
            cost = 20,
            id = {31},
            type = "offensive"
        },
        ["HedgeWildChildMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "MG",
            cost = 20,
            id = {77},
            type = "offensive"
        },
        ["MaddoxMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "BuggyMG",
            cost = 20,
            id = {48},
            type = "offensive"
        },
        ["StonewallCannon"] = 
        {
            name = "Machine Gun",
            description = "Adds a cannon to the vehicle.",
            template = "Cannon",
            cost = 20,
            id = {18},
            type = "offensive"
        },
        ["ChippewaRockets"] = 
        {
            name = "Rockets and Machine Gun",
            description = "Adds rockets and machine guns to the vehicle.",
            template = "Dome",
            cost = 70,
            id = {62},
            type = "offensive"
        },
        ["ChippewaMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds machine guns to the vehicle.",
            template = "default",
            cost = 30,
            id = {62},
            type = "offensive"
        },
        ["SivirkinRockets"] = 
        {
            name = "Rockets",
            description = "Adds rockets to the vehicle.",
            template = "WeaponUpgrade1",
            cost = 30,
            id = {62},
            type = "offensive"
        },
        ["PolomaRenegadeMachineGun"] = 
        {
            name = "Machine Gun",
            description = "Adds a machine gun to the vehicle.",
            template = "Armed",
            cost = 20,
            id = {7},
            type = "offensive"
        },
    },
    templates = -- Use these templates for spawning
    {
        [69] = {chance = 0.1, templates = {"Armed"}}, -- winstons amen party boat
        [88] = {chance = 1, templates = {"Default"}}, -- only default mta powerruns without weapons spawn in the wild
        [5] = {chance = 0.6, templates = {"Cab", "Fishing"}},
        [11] = {chance = 0.5, templates = {"Civil"}},
        [78] = {chance = 0.5, templates = {"Cab"}},
        [91] = {chance = 0.6, templates = {"Hardtop", "Softtop"}},
        [66] = {chance = 0.2, templates = {"Double"}},
        [40] = {chance = 0.1, templates = {"Crane"}},
        [56] = {chance = 1, templates = {"Cab"}}, -- default spawn
        [84] = {chance = 0.5, templates = {"Cab"}},
        [31] = {chance = 0.5, templates = {"Cab"}},
        [77] = {chance = 1, templates = {"Default"}}, -- default spawn
        [18] = {chance = 0.5, templates = {"Russian"}},
        [87] = {chance = 0.5, templates = {"Cab", "Softtop"}},
        [46] = {chance = 0.4, templates = {"Cab"}},
        [62] = {chance = 1, templates = {"UnArmed"}}, -- default
        [7] = {chance = 1, templates = {"Default"}} -- default
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