DroneRegionEnum = 
{
    FinancialDistrict = 1,
    ParkDistrict = 2,
    DocksDistrict = 3,
    ResidentialDistrict = 4,
    LostIsland = 5,
    LostIslandInner = 6,
    Desert = 6
}

DRONE_SPAWN_INTERVAL = 15

DroneRegions = 
{
    [DroneRegionEnum.FinancialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-10314, 203, -3000),
        level_range = {min = 1, max = 5},
        spawn = 
        {
            max = 100, -- Max drones alive at one time
            chance = 0.9 -- Chance of a drone spawning every interval
        },
        drone_spawn_rate = {}
    },
    [DroneRegionEnum.ParkDistrict] = 
    {
        radius = 1000,
        center = Vector3(-12708, 234, -4778),
        level_range = {min = 3, max = 10},
        spawn = 
        {
            max = 120, -- Max drones alive at one time
            chance = 0.9 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.DocksDistrict] = 
    {
        radius = 900,
        center = Vector3(-15321, 203, -2815),
        level_range = {min = 10, max = 30},
        spawn = 
        {
            max = 100, -- Max drones alive at one time
            chance = 0.8 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.ResidentialDistrict] = 
    {
        radius = 1100,
        center = Vector3(-12507, 203, -1119),
        level_range = {min = 3, max = 10},
        spawn = 
        {
            max = 120, -- Max drones alive at one time
            chance = 0.9 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.LostIsland] = 
    {
        radius = 1500,
        center = Vector3(-13609, 366, -13458),
        level_range = {min = 20, max = 40},
        spawn = 
        {
            max = 100, -- Max drones alive at one time
            chance = 0.5, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 50
            }
        },
    },
    [DroneRegionEnum.LostIslandInner] = 
    {
        radius = 500,
        center = Vector3(-14062, 343, -14122),
        level_range = {min = 40, max = 50},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            chance = 0.6, -- Chance of a drone spawning every interval
            height = 
            {
                min = 250,
                max = 350
            }
        },
    },
    [DroneRegionEnum.Desert] = 
    {
        radius = 6000,
        center = Vector3(-7605, 234, 7313),
        level_range = {min = 5, max = 15},
        spawn = 
        {
            max = 250, -- Max drones alive at one time
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