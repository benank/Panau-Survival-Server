DroneRegionEnum = 
{
    FinancialDistrict = 1,
    ParkDistrict = 2,
    DocksDistrict = 3,
    ResidentialDistrict = 4,
    LostIsland = 5,
    LostIslandInner = 6,
    Desert = 6,
    CapeCarnival = 7,
    Casino = 8,
    TopRight = 9,
    BottomIslands = 10
}

DRONE_SPAWN_INTERVAL = 1

DroneRegions = 
{
    [DroneRegionEnum.FinancialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-10314, 203, -3000),
        level_range = {min = 1, max = 3},
        spawn = 
        {
            max = 25, -- Max drones alive at one time
            chance = 1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 20
            }
        },
        drone_spawn_rate = {}
    },
    [DroneRegionEnum.ParkDistrict] = 
    {
        radius = 1100,
        center = Vector3(-12708, 234, -4778),
        level_range = {min = 5, max = 15},
        spawn = 
        {
            max = 30, -- Max drones alive at one time
            chance = 0.8, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 50
            }
        },
    },
    [DroneRegionEnum.DocksDistrict] = 
    {
        radius = 900,
        center = Vector3(-15321, 203, -2815),
        level_range = {min = 15, max = 30},
        spawn = 
        {
            max = 30, -- Max drones alive at one time
            chance = 0.6 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.ResidentialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-12507, 203, -1119),
        level_range = {min = 5, max = 15},
        spawn = 
        {
            max = 25, -- Max drones alive at one time
            chance = 0.8, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 50
            }
        },
    },
    [DroneRegionEnum.LostIsland] = 
    {
        radius = 1500,
        center = Vector3(-13609, 366, -13458),
        level_range = {min = 30, max = 50},
        spawn = 
        {
            max = 30, -- Max drones alive at one time
            chance = 0.1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 40
            }
        },
    },
    [DroneRegionEnum.LostIslandInner] = 
    {
        radius = 200,
        center = Vector3(-14088, 500, -14142),
        level_range = {min = 40, max = 70},
        spawn = 
        {
            max = 10, -- Max drones alive at one time
            chance = 0.2, -- Chance of a drone spawning every interval
            height = 
            {
                min = 100,
                max = 300
            }
        },
    },
    [DroneRegionEnum.Desert] = 
    {
        radius = 6000,
        center = Vector3(-7605, 234, 7313),
        level_range = {min = 1, max = 60},
        spawn = 
        {
            max = 100, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.CapeCarnival] = 
    {
        radius = 700,
        center = Vector3(13815, 240, -2299),
        level_range = {min = 25, max = 40},
        spawn = 
        {
            max = 15, -- Max drones alive at one time
            chance = 0.1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 15
            }
        },
    },
    [DroneRegionEnum.Casino] = 
    {
        radius = 2000,
        center = Vector3(1414, 210, 1812),
        level_range = {min = 15, max = 30},
        spawn = 
        {
            max = 15, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.TopRight] = 
    {
        radius = 3000,
        center = Vector3(11468, 267, -8950),
        level_range = {min = 10, max = 25},
        spawn = 
        {
            max = 15, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.BottomIslands] = 
    {
        radius = 3500,
        center = Vector3(11468, 267, -8950),
        level_range = {min = 10, max = 30},
        spawn = 
        {
            max = 20, -- Max drones alive at one time
            chance = 0.5 -- Chance of a drone spawning every interval
        },
    }
}

function GetExtraHeightOfDroneFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return 0 end
    local height_data = region_data.spawn.height
    if not height_data then return 0 end

    return (height_data.max - height_data.min) * math.random() + height_data.min
end

function GetLevelFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return end
    return math.random(region_data.level_range.max - region_data.level_range.min) + region_data.level_range.min
end